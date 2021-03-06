if(getRversion() >= '2.15.1') globalVariables("gIndex")

mcoptions <- list(preschedule=FALSE, set.seed=TRUE)

# Create (new) factors out of factor and character columns
reFactorData <- function(data){
  if(is.data.frame(data)){
    indChar <- sapply(data, is.character)
    indFac <- sapply(data, is.factor)
    data[indChar | indFac] <- lapply(data[indChar | indFac], factor)
    return(data)
  }else{
    stop("Data must be in data.frame format.")
  }
}

filterVectorLogical <- function(columnFilter,myNames){
  if(!is.null(columnFilter)){
    ignoreMatrix = sapply(columnFilter, function(el,namedCols){
      grepl(el,namedCols)
    },namedCols=myNames)
    if(length(myNames)==1){
      ignoreCols = any(ignoreMatrix)
    }else{
      ignoreCols = apply(ignoreMatrix,1,any)
    }
    return(ignoreCols)
  }else{
    return(rep(FALSE,length(myNames)))    
  }
}


expString <- function(x){
  if(is.na(x)) return("NA")
  doubleBase = .Machine$double.base
  toBase10log = x / log(10)
  toBaselog = x / log(doubleBase)
  
  numMax = .Machine$double.max.exp
  numMin = .Machine$double.min.exp
    
  if(toBaselog>numMax){
    first <- prettyNum( 10 ^ (toBase10log - floor(toBase10log)) ) 
    second <- prettyNum( floor(toBase10log) )
    return( paste( first, "e+", second, sep="" ) )
  }else if(toBaselog < numMin){
    first <- prettyNum( 10 ^ (1 - (ceiling(toBase10log) - toBase10log)) )
    second <- prettyNum( ceiling(toBase10log)-1 )
    return( paste( first, "e", second, sep="" ) )    
  }else{
    return( prettyNum( exp(x) ) )
  }
}


alphabetizeTerms <- function(trms){
  splt = strsplit(trms,":",fixed=TRUE)
  sorted=lapply(splt, function(trm){
    if(length(trm)==1) return(trm)
    trm = sort(trm)
    paste(trm,collapse=":")
  })
  sorted = unlist(sorted)
  
  return(sorted)
}

whichOmitted <- function(numerator, full){
  fullFmla <- formula(full@identifier$formula)
  numFmla <- formula(numerator@identifier$formula)

  fullTrms <- attr(terms(fullFmla), "term.labels")
  numTrms <- attr(terms(numFmla), "term.labels")
  
  fullTrms = alphabetizeTerms(fullTrms)
  numTrms = alphabetizeTerms(numTrms)
  
  omitted = fullTrms[!(fullTrms %in% numTrms)]
  if(any( !(numTrms %in% fullTrms) )) stop("Numerator not a proper restriction of full.")
  return(omitted)
}


propErrorEst = function(logX){
  logX = logX[!is.na(logX)]
  n = length(logX)
  logSumX = logMeanExpLogs(logX) + log(n)
  logSumX2 = logMeanExpLogs(2*logX) + log(n)
  sqrt((exp(logSumX2 - 2*logSumX) - 1/n) * (n/(n-1)))
}

combn2 <- function(x,lower=1){
  unlist(lapply(lower:length(x),function(m,x) combn(x,m,simplify=FALSE),x=x),recursive=FALSE)
}

stringFromFormula <- function(formula){
  oneLine = paste(deparse(formula),collapse="")
  sub("\\s\\s+"," ", oneLine, perl=TRUE) # get rid of extra spaces
}

fmlaFactors <- function(formula, data){
  rownames(attr(terms(formula, data = data),"factors"))
}

are.factors<-function(df) sapply(df, function(v) is.factor(v))

`%com%` <- function(x,y){
  common = intersect(names(x),names(y))
  if(length(common)==0) return(logical(0))
  all(sapply(common, function(el,x,y) identical(x[el],y[el]), x=x,y=y))
}

randomString <- function(x=1){
  n = ifelse(length(x)>1, length(x), x)
  substring(tempfile(rep("",n),"",""),2)
}

rpriorValues <- function(modelType,effectType=NULL,priorType=NULL){
  if(length(priorType)>1 | is.numeric(priorType)){
    return(priorType)
  }else if(length(priorType)==0){
    return(NULL)
  }
  
  if(modelType=="allNways"){
    return(
      switch(effectType,
             fixed = switch(priorType, 
                            ultrawide=1,
                            wide=sqrt(2)/2, 
                            medium=1/2, 
                            stop("Unknown prior type.")),
             random = switch(priorType, 
                             wide=sqrt(2)/2, 
                             medium=1/2, 
                             nuisance=1,
                             ultrawide=1,
                             stop("Unknown prior type.")),
             stop("Unknown prior type.")
      )
    )
  }
  
  if(modelType=="ttestTwo"){
    return(
      switch(priorType, 
             ultrawide=sqrt(2),
             wide=1, 
             medium=sqrt(2)/2, 
             stop("Unknown prior type."))  
    )
  }

  if(modelType=="ttestOne"){
    return(
      switch(priorType, 
             ultrawide=sqrt(2),
             wide=1, 
             medium=sqrt(2)/2, 
             stop("Unknown prior type."))  
    )
  }
  
  
  if(modelType=="regression"){
    #return(1)
    return(
      switch(priorType,
             ultrawide=sqrt(2)/2,
             wide=1/2, 
             medium=sqrt(2)/4,
             stop("Unknown prior type.")
      )
    )
    
  }
  
  stop("Unknown prior type.")
}


dinvgamma = function (x, shape, scale = 1) 
{
    if (shape <= 0 | scale <= 0) {
        stop("Shape or scale parameter negative in dinvgamma().\n")
    }
    alpha <- shape
    beta <- scale
    log.density <- alpha * log(beta) - lgamma(alpha) - (alpha + 
        1) * log(x) - (beta/x)
    return(exp(log.density))
}

# Taken from the WLE package source by Claudio Agostinelli <claudio at unive.it>
binary <- function(x, dim) {

   if (x==0) {
       pos <- 1
   } else {
       pos <- floor(log(x, 2))+1
   }

   if (!missing(dim)) {
       if (pos<=dim) {
           pos <- dim
       } else {
           warning("the value of `dim` is too small")
       }  
   }

   bin <- rep(0, pos)
   dicotomy <- rep(FALSE, pos)
   for (i in pos:1) {
        bin[i] <- floor(x/2^(i-1))
        dicotomy[i] <- bin[i]==1
        x <- x-((2^(i-1))*bin[i])
   }
   return(list(binary=bin, dicotomy=dicotomy))
}

# Construct all monotone Boolean functions for m arguments
monotoneBoolean <- function(m){
  if(m==0){
    return(list(FALSE,TRUE))
  }else{
    m0 = monotoneBoolean(m-1)
    m1 = list()
    for(i in 1:length(m0))
      for(j in 1:length(m0)){
        if(identical((m0[[i]] | m0[[j]]), m0[[j]])){
          m1[[length(m1)+1]] = c(m0[[i]],m0[[j]])
        }   
      }
    return(m1)
  }
}

# Construct all monotone Boolean functions for m arguments
# but output in nice format (matrix)
monotoneBooleanNice = function(m){
  mb = monotoneBoolean(m)
  n = length(mb)
  mb = unlist(mb)
  dim(mb) = c(length(mb)/n,n)
  t(mb)
}

makeTerm <- function(m,factors){
  trms = factors[binary(m,length(factors))$dicotomy]
  paste(trms,collapse=":")
}

setMethod("%termin%", signature = c(x="character",table="character"),
          function(x,table){
            table = strsplit(table,":",fixed=TRUE)
            x = strsplit(x,":",fixed=TRUE)
            returnVector = rep(FALSE,length(x))
            for(i in 1:length(x))
              for(j in 1:length(table)){
                found = all(table[[j]] %in% x[[i]]) & all(x[[i]] %in% table[[j]])
                returnVector[i] = returnVector[i] | found
              }
            return(returnVector)
          })

setMethod("%termin%", signature = c(x="character",table="NULL"),
          function(x,table){
            return(rep(FALSE,length(x)))
           })


termMatch <- function(x, table, nomatch = NA_integer_){
  returnVector = rep(nomatch,length(x))
  if(is.null(table)){
    return(returnVector)
  }
  table = strsplit(table,":",fixed=TRUE)
  x = strsplit(x,":",fixed=TRUE)
  for(i in 1:length(x))
    for(j in 1:length(table)){
      found = all(table[[j]] %in% x[[i]]) & all(x[[i]] %in% table[[j]])
      if(is.na(returnVector[i]) & found) returnVector[i] = j
    }
  return(returnVector)
}

# Add two values for which the proportional error is known
# and return the proportional error
sumWithPropErr <- function(x1,x2,err1,err2){
  # convert proportional error to abs err
  logAbs1 = x1 + log(err1)
  logAbs2 = x2 + log(err2)
  # Compute the logarithms of sums of exponentiated logarithms, safely
  logSum = logMeanExpLogs(c(x1, x2)) + log(2)
  absSum = .5 * (logMeanExpLogs(2*c(logAbs1, logAbs2)) + log(2))
  
  propErr = exp(absSum - logSum)
  return(c(logSum,propErr))
}

# Return log(exp(a) - exp(b)), without losing precision
logExpAminusExpB <- function(a,b)
  a + pexp(a-b,log.p=TRUE)


