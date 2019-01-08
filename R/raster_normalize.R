#' Normalize a raster layer
#'
#' Normalize rasterlayer values between 0 and 1
#'
#' @param x a raster layer
#' @return returns a normalized matrix or vector
#' @keywords foto, radial spectrum, normalization
#' @export
#' @examples
#'
#' \donttest{
#' # fake raster data
#' x <- raster::raster(matrix(1:10, ncol = 2))
#' x <- raster_normalize(x)
#'}

raster_normalize <- function(x){
 (x - min(raster::getValues(x), na.rm=TRUE))/
  (max(raster::getValues(x),na.rm=TRUE) - min(raster::getValues(x), na.rm=TRUE))
}
