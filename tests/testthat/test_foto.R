context("Test main functions")

# read in data
r <- raster("inst/extdata/field_plots.png")

# test zones
foto(r, windowsize = 25, method = "zones")

# test moving window
r <- crop(r, extent(1,100,1,100))
foto(r, plot = TRUE, windowsize = 25, method = "mw")
