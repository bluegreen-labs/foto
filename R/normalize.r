#' Normalize a matrix or vector
#'
#' Normalize values between 0 and 1
#'
#' @param x a matrix or vector
#' @return returns a normalized matrix or vector
#' @keywords foto, radial spectrum, normalization
#' @export
#' @examples
#'
#' \donttest{
#' x <- c(1,5,10)
#' print(normalize(x))
#'}

# standard normalize between 0 - 1
normalize <- function(x){
  (x - min(x, na.rm=TRUE))/(max(x,na.rm=TRUE) - min(x, na.rm=TRUE))
}