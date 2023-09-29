#' Calculates FOTO classification of texture
#'
#' Note that the input matrix should be square or results will be discarded
#  the output is an increment to i (global) and data that is
#  written matrix 'output' (global) to be defined up front.
#'
#' @param x an image file, or single or multi-layer SpatRaster
#' (RGB or otherwise), multi-layer data are averaged to a single layer
#' @param window_size a moving window size in pixels (default = 61 pixels)
#' @param method zones (for discrete zones) or mw for a moving window
#' approach
#' @param pca execute PCA, \code{TRUE} or \code{FALSE}. If \code{FALSE} only
#' the radial spectra are returned for additional manipulation. Plotting is
#' ignored if set to \code{FALSE}.
#' @param norm_spec normalize radial spectrum,
#' bolean \code{TRUE} or \code{FALSE}
#' @param high_pass apply high pass filter to radial spectra,
#' bolean \code{TRUE} or \code{FALSE}
#' @param plot plot output, bolean \code{TRUE} or \code{FALSE}
#' @return returns a radial spectrum for a moving window across a
#' raster layer
#' @seealso \code{\link[foto]{rspectrum}}
#' @export
#' @examples
#' \dontrun{
#' # load demo data
#' r <- terra::rast(system.file("extdata",
#'   "yangambi.png",
#'   package = "foto",
#'   mustWork = TRUE
#' ))
#'
#' # classify pixels using zones (discrete steps)
#' output <- foto(r,
#'   plot = FALSE,
#'   window_size = 25,
#'   method = "zones"
#' )
#'
#' # print data structure
#' print(names(output))
#' }
#'
foto <- function(x,
                 window_size = 61,
                 method = "zones",
                 norm_spec = FALSE,
                 high_pass = TRUE,
                 pca = TRUE,
                 plot = FALSE) {
  
  # get the current enviroment
  env <- environment()

  # check for image
  if (missing(x)) {
    stop("No image or RasterLayer / Stack or Brick provided.")
  }

  # read the image / matrix file and apply extract the r-spectra
  if (!grepl("SpatRaster", class(x))) {
    # check file
    if (!file.exists(x)) {
      stop("Incorrect image path.")
    }

    # if not a raster object read as image
    img <- suppressWarnings(terra::rast(x))

    # calculate the mean (grayscale)
    # image if there is more than one
    # image band
    img <- terra::mean(img)
  }

  if (inherits(x, "SpatRaster")) {
    if (dim(x)[3] > 1) {
      img <- terra::mean(x)
    } else {
      img <- x
    }
  }

  if(method == "zones" || method == "mw"){
    if(method=="zones"){
      # get number of cells to be aggregated to
      N <- ceiling(nrow(img)/window_size)
      M <- ceiling(ncol(img)/window_size)
      cells <- N*M
    }else{
      # get number of cells to be aggregated to
      N <- nrow(img)
      M <- ncol(img)
      cells <- N*M
    }
  }else{
    print("Choose an available method: zones or mw")
  }

  # use assign
  # define output matrix and global increment, i
  if (window_size / 2 < 29) {
    output <- matrix(0, cells + 1, window_size / 2)
  } else {
    output <- matrix(0, cells, 29)
  }

  # see rspectrum function above
  i <- 0

  # for every zone execute the r-spectrum function
  if (method == "zones") {
    zones <- terra::aggregate(
        img,
        fact = window_size,
        fun = function(x, ...) {
          rspectrum(
            x = x,
            w = window_size,
            n = norm_spec,
            h = high_pass,
            env = env
          )
        },
        na.rm = TRUE
      )
  } else {
    message("A moving window approach is computationally intensive.")
    message("This might take a while.")
    zones <- terra::focal(
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
        expand = FALSE,
        na.rm = TRUE
      )
  }

  # 3. reformat the r-spectrum output (normalize) and apply a PCA
  # set all infinite values to NA
  output[is.infinite(output)] <- NA

  if (pca) {
    # Normalize matrix column wise (ignoring NA values)
    noutput <- suppressWarnings(base::scale(output))

    # set NA/Inf values to 0 as the pca analys doesn't take NA values
    noutput[is.infinite(noutput) | is.na(noutput)] <- 0

    # find the location of all zero rows (empty)
    zero_location <- apply(noutput, 1, function(x) all(x == 0))

    # the principal component analysis
    pcfit <- stats::princomp(noutput)

    # set empty (zeros) rows to NA
    pcfit$scores[which(zero_location), ] <- NA

    # create reclass files based upon PCA scores
    # only the first 3 PC will be considered
    for (i in 1:3) {
      assign(paste("rcl.", i, sep = ""),
        cbind(
          seq(1, nrow(pcfit$scores), 1),
          normalize(pcfit$scores[, i])
        ),
        envir = env
      )
    }
    
    # reclassify using the above reclass files
    PC <- lapply(1:3, function(i) {
      return(
          terra::classify(
            zones,
            get(paste("rcl.", i, sep = ""))
          )
        )
    })

    # create a raster brick
    img_RGB <- suppressWarnings(do.call("c", PC))

    # plot the classification using an RGB representation of the first 3 PC
    if (plot) {
      terra::plot(img,
        col = grDevices::gray(0:100 / 100),
        legend = FALSE,
        axes = FALSE
      )
      terra::plotRGB(
        img_RGB,
        add = TRUE,
        scale = 255,
        stretch = "hist",
        bgalpha = 0,
        alpha = 0.5
      )
    }
  } else {
    img_RGB <- NULL
  }

  # return data
  return(list(
    "zones" = zones,
    "radial_spectra" = output,
    "rgb" = img_RGB
  ))
}
