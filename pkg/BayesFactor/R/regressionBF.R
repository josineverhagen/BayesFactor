

##' This function simultaneously computes Bayes factors for groups of models in 
##' regression designs
##' 
##' \code{regressionBF} computes Bayes factors to test the hypothesis that 
##' slopes are 0 against the alternative that all slopes are nonzero.
##' 
##' The vector of observations \eqn{y} is assumed to be distributed as \deqn{y ~
##' Normal(\alpha 1 + X\beta, \sigma^2 I).} The joint prior on 
##' \eqn{\alpha,\sigma^2} is proportional to \eqn{1/\sigma^2}, the prior on 
##' \eqn{\beta} is \deqn{\beta ~ Normal(0, N g \sigma^2(X'X)^{-1}).} where 
##' \eqn{g ~ InverseGamma(1/2,r/2)}. See Liang et al. (2008) section 3 for 
##' details.
##' 
##' Possible values for \code{whichModels} are 'all', 'top', and 'bottom', where
##' 'all' computes Bayes factors for all models, 'top' computes the Bayes 
##' factors for models that have one covariate missing from the full model, and 
##' 'bottom' computes the Bayes factors for all models containing a single 
##' covariate. Caution should be used when interpreting the results; when the 
##' results of 'top' testing is interpreted as a test of each covariate, the 
##' test is conditional on all other covariates being in the model (and likewise
##' 'bottom' testing is conditional on no other covariates being in the model).
##' 
##' An option is included to prevent analyzing too many models at once: 
##' \code{options('BFMaxModels')}, which defaults to 50,000, is the maximum 
##' number of models that `regressionBF` will analyze at once. This can be
##' increased by increasing the option value.
##' 
##' For the \code{rscaleCont} argument, several named values are recongized: 
##' "medium", "wide", and "ultrawide", which correspond \eqn{r} scales of 
##' \eqn{\sqrt{2}/4}{sqrt(2)/4}, 1/2, and \eqn{\sqrt{2}/2}{sqrt(2)/2},
##' respectively. These values were chosen to yield consistent Bayes factors
##' with \code{\link{anovaBF}}.
##' @title Function to compute Bayes factors for regression designs
##' @param formula a formula containing all covariates to include in the 
##'   analysis (see Examples)
##' @param data a data frame containing data for all factors in the formula
##' @param whichModels which set of models to compare; see Details
##' @param progress if \code{TRUE}, show progress with a text progress bar
##' @param rscaleCont prior scale on all standardized slopes
##' @param noSample if \code{TRUE}, do not sample, instead returning NA.
##' @param callback callback function for third-party interfaces 
##' @return An object of class \code{BFBayesFactor}, containing the computed 
##'   model comparisons
##' @author Richard D. Morey (\email{richarddmorey@@gmail.com})
##' @references Liang, F. and Paulo, R. and Molina, G. and Clyde, M. A. and 
##'   Berger, J. O. (2008). Mixtures of g-priors for Bayesian Variable 
##'   Selection. Journal of the American Statistical Association, 103, pp. 
##'   410-423
##'   
##'   Rouder, J. N.  and Morey, R. D. (in press). Bayesian testing in 
##'   regression. Multivariate Behavioral Research.
##'   
##'   Zellner, A. and Siow, A., (1980) Posterior Odds Ratios for Selected 
##'   Regression Hypotheses.  In Bayesian Statistics: Proceedings of the First 
##'   Interanational Meeting held in Valencia (Spain).  Bernardo, J. M., 
##'   Lindley, D. V., and Smith A. F. M. (eds), pp. 585-603.  University of 
##'   Valencia.
##' @export
##' @keywords htest
##' @examples
##' ## See help(attitude) for details about the data set
##' data(attitude)
##' 
##' ## Classical regression
##' summary(fm1 <- lm(rating ~ ., data = attitude))
##' 
##' ## Compute Bayes factors for all regression models
##' output = regressionBF(rating ~ ., data = attitude, progress=FALSE)
##' head(output)
##' ## Best model is 'complaints' only
##' 
##' ## Compute all Bayes factors against the full model, and 
##' ## look again at best models
##' head(output / output[63])
##' 
##' @seealso \code{\link{lmBF}}, for testing specific models, and 
##'   \code{\link{anovaBF}} for the function similar to \code{regressionBF} for 
##'   ANOVA models.

regressionBF <- function(formula, data, whichModels = "all", progress=options()$BFprogress, rscaleCont = "medium", callback = function(...) as.integer(0), noSample=FALSE)
{
  checkFormula(formula, data, analysis = "regression")
  dataTypes <- createDataTypes(formula, whichRandom=c(), data, analysis = "regression")
  fmla <- createFullRegressionModel(formula, data)
  
  models <- enumerateRegressionModels(fmla, whichModels, data)
  
  if(length(models)>options()$BFMaxModels) stop("Maximum number of models exceeded (", 
                                                length(models), " > ",options()$BFMaxModels ,"). ",
                                                "The maximum can be increased by changing ",
                                                "options('BFMaxModels').")
  
  bfs = NULL
  if(progress){
    pb = txtProgressBar(min = 0, max = length(models), style = 3)
  }else{
    pb = NULL
  }
  for(i in 1:length(models)){
    oneModel <- lmBF(models[[i]],data = data, dataTypes = dataTypes,
                     rscaleCont = rscaleCont,noSample=noSample)
    if(inherits(pb,"txtProgressBar")) setTxtProgressBar(pb, i)
    cb = callback( (i - 1)/length(models) * 1000 )
    if(cb != 0) stop("Operation cancelled: code ", cb)
    bfs = c(bfs,oneModel)
  }
  if(inherits(pb,"txtProgressBar")) close(pb)

  bfObj = do.call("c", bfs)
  if(whichModels=="top") bfObj = BFBayesFactorTop(bfObj)
  return(bfObj)
}


