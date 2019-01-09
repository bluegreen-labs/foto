#' Calculates a radial spectrum
#'
#' This is an internal function and not to be used stand-alone.
#'
#' @param x a square matrix
#' @param w a moving window size
#' @param n normalize, bolean \code{TRUE} or \code{FALSE}
#' @param env local environment to evaluate
#' @param ... additional parameters to forward
#' @return Returns a radial spectrum values for the image used
#' in order to classify texture using a PCA (or other) analysis.
#' @keywords foto, radial spectrum

rspectrum <- function(
  x,
  w,
  n = TRUE,
  env,
  ...
  ){

  # increment
  i <- get("i", envir = env)
  assign("i", i + 1, envir = env)
    
  # check if variable x is square
  # we need to pass the window size
  # as we can't deduce this from the number of values alone
  # as the values are passed as a vector not a matrix
  if ( w == sqrt(length(x)) ){
    
    # convert to square matrix
    im <- matrix(x,w,w)
    
    # extract the squared amplitude of the FFT
    fftim <- Mod(stats::fft(im))^2
    
    # calculate distance from the center of the image
    offset <- ceiling(dim(im)[1]/2)
    
    # define distance matrix
    # r is rounded to an integer by zonal
    r <- sqrt((col(im)-offset)^2 + (row(im)-offset)^2)
          
    # calculate the mean spectrum for distances r
    # (note: reverse the order of the results to center
    # the FFT spectrum)
    rspec <- rev(raster::zonal(
      raster::raster(fftim),
      raster::raster(r),
      fun = 'mean',
      na.rm = TRUE)[,2])
        
    if (n){
      
      # Normalize by dividing with the image standard deviation
      # publictions are inconsisten on the use of normalization
      # need to clarify this better.
      rspec <- rspec/stats::sd(im,na.rm=TRUE)
    
    }    
    
    # set first two values to 0 these are inherent to the
    # structure of the image
    rspec[1:2] <- 0
    
    # only use the first 29 useful harmonics of the r-spectrum
    # in accordance to ploton et al. 2012
    output <- get("output", envir = env)
    
    if( w/2 < 29){
      output[i,] <- rspec[1:(w/2)]
    }else{
      output[i,] <- rspec[1:29]
    }
    
    # assign values to matrix
    assign("output", output, envir = env)
    
    # always return i (index for mapping)
    return(i)
    
  }else{
    
    # if not square return i as well (index for mapping)
    return(i)
  }
}
