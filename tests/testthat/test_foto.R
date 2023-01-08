context("Test main functions")

test_that("test zones",{
  
  # filename
  x <- system.file("extdata", "yangambi.png",
                          package = "foto",
                          mustWork = TRUE)
  
  # classify pixels using zones
  expect_output(str(foto(x = suppressWarnings(terra::rast(x)), plot = FALSE)))
  expect_output(str(foto(x = suppressWarnings(terra::rast(x)), plot = FALSE)))
  expect_output(str(foto(x = x, plot = FALSE)))
  expect_output(str(foto(x = suppressWarnings(terra::rast(x)), plot = TRUE)))
  
  # no image
  expect_error(foto())
  expect_error(foto(x = "./no_image.png"))
  
  # faulty method
  expect_error(foto(x = suppressWarnings(terra::rast(x)),
                         plot = FALSE,
                         method = "xx"))
  
})

test_that("test mw",{
  
  # test moving window
  r <- terra::crop(
    suppressWarnings(
      terra::rast(system.file("extdata", "yangambi.png",
                              package = "foto",
                              mustWork = TRUE))
    ),
    terra::ext(1,30,1,30))
  
  # test moving window
  expect_output(str(foto(r,
                         plot = FALSE,
                         window_size = 25,
                         method = "mw")))
})

test_that("test normalization",{
  x <- c(1,5,10)
  expect_output(str(normalize(x)))
  expect_error(normalize())
})

test_that("test batch processing",{
  
  path <- system.file("extdata", package = "foto")
  
  # classify pixels using zones (discrete steps)
  expect_output(str(
    foto_batch(
      path = path,
      window_size = 51,
      method = "zones"
      )
    )
  )
})




