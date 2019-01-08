#' Calculates FOTO classification of texture
#'
#' Note that the input matrix should be square or results will be discarded 
#  the output is an increment to i (global) and data that is
#  written matrix 'output' (global) to be defined up front. 
#'
#' @param x a raster layer
#' @param window_size a moving window size, default = 64 pixels
#' @param plot plot output, bolean \code{TRUE} or \code{FALSE}
#' @param method zones (for discrete zones) or mw for a moving window
#' approach
#' @param rspectrum.n normalize radial spectrum,
#' bolean \code{TRUE} or \code{FALSE}
#' @return returns a radial spectrum for a moving window across a
#' raster layer
#' @keywords foto, radial spectrum
#' @seealso \code{\link[foto]{rspectrum}}
#' @export
#' @examples
#'
#' \donttest{
#' # read in raster
#' 
#' # calculate spectrum
#' 
#'}


foto <- function(
  x,
  windowsize = 61,
  method = "zones",
  plot = FALSE,
  rspectrum.n = TRUE
  ){
  
  # get the current enviroment
  env <- environment()
  
  # 2. read the image / matrix file and apply extract the r-spectra
  if (class(x)[1]!="RasterLayer" || class(x)[1]!="RasterBrick" ){  
    # if not a raster object read as image
    img <- brick(x)
    
    # calculate the mean (grayscale)
    # image if there is more than one
    # image band
    if(nbands(img)>1){
      img <- mean(img)
    }
  }
  
  if (class(x)[1]=="RasterLayer"){
    img <- x 
  }
  
  if (class(x)[1]=="RasterBrick"){
    img <- x
    
    # calculate the mean (grayscale)
    # image if there is more than one
    # image band
    if(nbands(img)>1){
      img <- mean(img)
    }
  }
  
  if(method=="zones"|method=="mw"){
    if(method=="zones"){
      # get number of cells to be aggregated to
      N <- ceiling(img@nrows/windowsize)
      M <- ceiling(img@ncols/windowsize)
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
  if( windowsize/2 < 29){
    output <- matrix(0, cells, windowsize/2)
  }else{
    output <- matrix(0, cells, 29)
  }
  
  # see rspectrum function above
  i <- 0
  
  # for every zone execute the r-spectrum function
  if(method=="zones"){
    zones <- aggregate(img,
                        fact=windowsize,
                        fun=function(x,...){
                          rspectrum(x=x,
                                    w=windowsize,
                                    n=rspectrum.n,
                                    env = env,
                                    ...)},
                        expand = TRUE,
                        na.rm = TRUE)
  }else{
    message("A moving window approach is computationally intensive.")
    message("This might take a while.")
    zones <- focal(img,
                    matrix(rep(1,windowsize*windowsize),
                           ncol = windowsize,
                           nrow = windowsize),
                    fun=function(x,...){
                      rspectrum(x = x,
                                w = windowsize,
                                n = rspectrum.n,
                                env = env,
                                ...)},
                    expand = TRUE,
                    na.rm = TRUE)
  }
  
  # 3. reformat the r-spectrum output (normalize) and apply a PCA
  # set all infinite values to NA
  output[is.infinite(output)] <- NA
  
  # normalize matrix column wise (ignoring NA values)
  # (this routine doesn't increase the accuracy of the
  # resulting map, if not it produces worse output. 
  # uncomment the code if wanted)
  
  # normalize column wise by substracting the mean
  # and dividing with the standard deviation
  # keep original input file for reference
  # look up reference!
  # NOTE: use base::scale???
  noutput <- base::scale(output)
  
  # set NA/Inf values to 0 as the pca analys doesn't take NA values
  noutput[is.infinite(noutput) | is.na(noutput)] <- 0
  
  # the principal component analysis
  pcfit <- princomp(noutput)
  
  # create reclass files based upon PCA scores
  # only the first 3 PC will be considered
  for (i in 1:3){
    assign(paste('rcl.',i,sep=''),
           cbind(1:length(pcfit$scores[,i]),
                 normalize(pcfit$scores[,i])),
           envir=env)
  }  
  
  # reclassify using the above reclass files
  for (i in 1:3){
    # get() reclass matrix and reclassify the zones file
    assign(paste('PC.',i,sep=''),
           reclassify(zones,get(paste('rcl.',i,sep=''))),
           envir=env)                                
  }
  
  # create a raster brick and plot the RGB image
  # made of pca scores, colours correspond to
  # different scores as split between the scores
  # of the first three pca axis
  img_RGB <- raster::brick(PC.1,PC.2,PC.3)
  
  # 4. plot the classification using an RGB representation of the first 3 PC
  if (plot){ # if print is true print the pca classification results
    raster::plot(img,
                 col = gray(0:100/100),
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
              "output" = output,
              "RGB" = img_RGB))
}
