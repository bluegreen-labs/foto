#' Calculates FOTO classification of texture for an image batch
#'
#' This routine process images as a batch, normalizing the PCA
#' analysis across images. This global normalization makes it possible
#' to compare the resulting PCA scores across images and infer trends
#' over different remote sensing tiles or across time.
#'
#' @param path directory containing (only) image files to process
#' @param window_size a moving window size in pixels (default = 61 pixels)
#' @param method zones (for discrete zones) or mw for a moving window
#' approach
#' @param cores number of cores to use in parallel calculations
#' @return returns a radial spectrum for a moving window across a
#' raster layer
#' @seealso \code{\link[foto]{rspectrum}} \code{\link[foto]{foto}}
#' @export
#' @examples
#' \dontrun{
#' # load demo data path
#' path <- system.file("extdata", package = "foto")
#'
#' # classify pixels using zones (discrete steps)
#' output <- foto_batch(
#'   path = path,
#'   window_size = 25,
#'   method = "zones"
#' )
#' }
#'
foto_batch <- function(path,
                       window_size = 61,
                       method = "zones",
                       cores = 1) {
  # get the current enviroment
  env <- environment()

  if (missing(path)) {
    stop("no path specified")
  }

  if (!dir.exists(path)) {
    stop("path does not exist")
  }

  # list all files
  files <- list.files(
    path = path,
    pattern = "*",
    recursive = FALSE,
    full.names = TRUE
  )

  # run the normal routine
  output <- parallel::mclapply(files, function(file) {
    foto(
      file,
      window_size = window_size,
      method = method,
      plot = FALSE,
      norm_spec = FALSE,
      pca = FALSE
    )
  },
  mc.cores = cores
  )

  # combine r-spectra
  i <- 1
  r_spectra <- do.call(
    "rbind",
    lapply(output, function(x) {
      index <- get("i", envir = env)
      assign("i", index + 1, envir = env)
      return(cbind(index, x$radial_spectra))
    })
  )

  # grab the index
  index <- r_spectra[, 1]

  # Normalize matrix column wise (ignoring NA values)
  noutput <- suppressWarnings(base::scale(r_spectra[, -1]))

  # set NA/Inf values to 0 as the pca analys doesn't take NA values
  noutput[is.infinite(noutput) | is.na(noutput)] <- 0

  # find the location of all zero rows (empty)
  zero_location <- apply(noutput, 1, function(x) all(x == 0))

  # the principal component analysis
  pcfit <- stats::princomp(noutput)

  # set empty (zeros) rows to NA
  pcfit$scores[which(zero_location), ] <- NA

  pc_images <- lapply(
    files,
    function(file) {
      # grab file index
      f_i <- which(files %in% file)

      # grab zones
      zones <- output[[f_i]]$zones

      # create reclass files based upon PCA scores
      # only the first 3 PC will be considered
      for (i in 1:3) {
        assign(paste("rcl.", i, sep = ""),
          cbind(
            seq(1, length(pcfit$scores[index == f_i, i]), 1),
            normalize(pcfit$scores[index == f_i, i])
          ),
          envir = env
        )
      }

      # reclassify using the above reclass files
      PC <- lapply(1:3, function(i) {
        return(terra::classify(
          zones,
          get(paste("rcl.", i, sep = ""))
        ))
      })

      # create a raster brick
      img_RGB <- do.call("c", PC)

      # return image file
      return(img_RGB)
    }
  )

  # assign file names to nested list
  names(pc_images) <- basename(files)

  # return all image files
  return(pc_images)
}
