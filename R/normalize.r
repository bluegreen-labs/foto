#' Normalize a matrix or vector
#'
#' Normalize values between 0 and 1, internal function only.
#'
#' @param x a matrix or vector
#' @return returns a normalized matrix or vector

# standard normalize between 0 - 1
normalize <- function(x){
  
  if (missing(x)){
    stop("missing vector or matrix")
  }
  suppressWarnings(
    (x - min(x, na.rm=TRUE))/(max(x,na.rm=TRUE) - min(x, na.rm=TRUE))
  )
}
