context("Test main functions")
library(foto)

# load demo data
file <- sprintf("%s/extdata/yangambi.png", path.package("foto"))
print(file)
r <- raster::raster(file)

test_that("test zones",{

  # classify pixels using zones
  expect_output(str(foto(r,
                 plot = FALSE,
                 window_size = 25,
                 method = "zones")))
  
  # plot data
  expect_output(str(foto(r,
                         plot = TRUE,
                         window_size = 25,
                         method = "zones")))
  
  # no image
  expect_error(foto(window_size = 25, method = "zones"))
  
})

test_that("test mw",{
  
  # test moving window
  r <- raster::crop(r, raster::extent(1,30,1,30))
  
  # test moving window
  expect_output(str(foto(r,
                         plot = FALSE,
                         window_size = 25,
                         method = "mw")))
})

