#' Calculates FOTO classification of texture
#'
#' Note that the input matrix should be square or results will be discarded 
#  the output is an increment to i (global) and data that is
#  written matrix 'output' (global) to be defined up front. 
#'
#' @param x an image file, raster layer, stack or brick 
#' for multilayered images (RGB or otherwise) data are averaged to 
#' a single layer raster
#' @param window_size a moving window size in pixels (default = 61 pixels)
#' @param plot plot output, bolean \code{TRUE} or \code{FALSE}
#' @param method zones (for discrete zones) or mw for a moving window
#' approach
#' @param norm_spec normalize radial spectrum,
#' bolean \code{TRUE} or \code{FALSE}
#' @return returns a radial spectrum for a moving window across a
#' raster layer
#' @keywords foto, radial spectrum
#' @seealso \code{\link[foto]{rspectrum}}
#' @importFrom raster brick
#' @export
#' @examples
#'
#' \donttest{
#' # load demo data
#' r <- raster::raster(system.file("extdata", "yangambi.png", package = "foto",
#'      mustWork = TRUE))
#' 
#' # classify pixels using zones (discrete steps)
#' output <- foto(r,
#'                plot = TRUE,
#'                window_size = 25,
#'                method = "zones")
#' 
#' # print data structure
#' print(names(output))
#'}


foto <- function(
  x,
  window_size = 61,
  method = "zones",
  plot = FALSE,
  norm_spec = TRUE
  ){
  
  # get the current enviroment
  env <- environment()
  
  # check for image
  if(missing(x)){
    stop("No image or RasterLayer / Stack or Brick provided.")
  }
  
  # read the image / matrix file and apply extract the r-spectra
  if (!grepl("Raster",class(x))){
    
    # check file
    if(!file.exists(x)){
      stop("Incorrect image path.")
    }
    
    # if not a raster object read as image
    img <- raster::brick(x)
    
    # calculate the mean (grayscale)
    # image if there is more than one
    # image band
    img <- raster::mean(img)
  }
  
  if (class(x)[1]=="RasterLayer"){
    img <- x 
  }
  
  if (class(x)[1]=="RasterBrick" ||
      class(x)[1]=="RasterStack"){
    
    # calculate the mean (grayscale)
    # image if there is more than one
    # image band
      img <- raster::mean(x)
  }
  
  if(method == "zones" || method == "mw"){
    if(method=="zones"){
      # get number of cells to be aggregated to
      N <- ceiling(img@nrows/window_size)
      M <- ceiling(img@ncols/window_size)
      cells <- N*M
    }else{
      # get number of cells to be aggregated to
      N <- img@nrows
      M <- img@ncols
      cells <- N*M
    }
  }else{
    print("Choose an available method: zones or mw")
  }
  
  # use assign
  # define output matrix and global increment, i
  if( window_size/2 < 29){
    output <- matrix(0, cells, window_size/2)
  }else{
    output <- matrix(0, cells, 29)
  }
  
  # see rspectrum function above
  i <- 0
  
  # for every zone execute the r-spectrum function
  if(method=="zones"){
    zones <- raster::aggregate(
      img,
      fact = window_size,
      fun = function(x, ...) {
        rspectrum(
          x = x,
          w = window_size,
          n = norm_spec,
          env = env
        )
      },
      expand = TRUE,
      na.rm = TRUE
    )
  }else{
    message("A moving window approach is computationally intensive.")
    message("This might take a while.")
    zones <- raster::focal(
      img,
      matrix(
        rep(1, window_size * window_size),
        ncol = window_size,
        nrow = window_size
      ),
      fun = function(x, ...) {
        rspectrum(
          x = x,
          w = window_size,
          n = norm_spec,
          env = env
        )
      },
      expand = TRUE,
      na.rm = TRUE
    )
  }
  
  # 3. reformat the r-spectrum output (normalize) and apply a PCA
  # set all infinite values to NA
  output[is.infinite(output)] <- NA
  
  # Normalize matrix column wise (ignoring NA values)
  noutput <- suppressWarnings(base::scale(output))
  
  # set NA/Inf values to 0 as the pca analys doesn't take NA values
  noutput[is.infinite(noutput) | is.na(noutput)] <- 0
  
  # the principal component analysis
  pcfit <- stats::princomp(noutput)
  
  # create reclass files based upon PCA scores
  # only the first 3 PC will be considered
  for (i in 1:3){
    assign(paste('rcl.',i,sep=''),
           cbind(seq(1, length(pcfit$scores[,i]), 1),
                 normalize(pcfit$scores[,i])),
           envir = env)
  }  
  
  # reclassify using the above reclass files
  PC <- lapply(1:3, function(i){
    return(raster::reclassify(zones,
                              get(paste('rcl.',i,sep=''))))
  })
  
  # create a raster brick
  img_RGB <- do.call("brick", PC)
  
  # plot the classification using an RGB representation of the first 3 PC
  if (plot){
    raster::plot(img,
                 col = grDevices::gray(0:100/100),
                 legend = FALSE,
                 box = FALSE,
                 axes = FALSE)
    raster::plotRGB(img_RGB,
                    stretch = 'hist',
                    add = TRUE, 
                    alpha = 128,
                    bgalpha = 0)
  }
  
  # return data
  return(list("zones" = zones, 
              "radial_spectra" = output,
              "rgb" = img_RGB))
}
