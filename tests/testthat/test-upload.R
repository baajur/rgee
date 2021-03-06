context("rgee: ee_upload test")

# Pre-checking ------------------------------------------------------
# Google credentials were loaded in the system?
skip_if_no_credentials <- function(user) {
  ee_path <- path.expand(sprintf("~/.config/earthengine/%s", user))
  credentials <- list.files(
    path = ee_path,
    pattern = "@gmail.com|credentials|GCS_AUTH_FILE.json"
  )
  if (length(credentials) != 3) {
    skip("All google credentials were not found")
  }
}

# Neccesary Python packages were loaded?
skip_if_no_pypkg <- function() {
  have_ee <- reticulate::py_module_available("ee")
  have_numpy <- reticulate::py_module_available("numpy")
  if (isFALSE(have_ee)) {
    skip("ee not available for testing")
  }
  if (isFALSE(have_numpy)) {
    skip("numpy not available for testing")
  }
}

# Init Earth Engine just if it is necessary
init_rgee <- function() {
  tryCatch(
    expr = ee$Image()$getInfo(),
    error = function(e) {
      ee_Initialize(
        email = 'data.colec.fbf@gmail.com',
        drive = TRUE,
        gcs = TRUE
      )
    }
  )
}

user <- "data.colec.fbf"
skip_if_no_credentials(user)
skip_if_no_pypkg()
init_rgee()
# -------------------------------------------------------------------------

test_that("local_to_gcs - character",{
  # Define an image.
  tif <- system.file("tif/L7_ETMs.tif", package = "stars")
  gcsuri <- local_to_gcs(x = tif, bucket = 'rgee_dev')
  gcsuri <- local_to_gcs(x = tif, bucket = 'rgee_dev',quiet = TRUE)
  expect_type(gcsuri,'character')
})

# ee_upload with bucket -----------------------------------------------------
test_that("gcs_to_ee_table ", {
  nc <- st_read(system.file("shape/nc.shp", package = "sf"))
  assetId <- sprintf("%s/%s",ee_get_assethome(),'sf_nc')
  zipfile <- ee_utils_shp_to_zip(nc)
  gs_uri <- local_to_gcs(x = zipfile,
                            bucket = 'rgee_dev')
  gcs_to_ee_table(
    gs_uri = gs_uri,
    assetId = assetId
  )
  #ee_monitoring()
  ee_sf_01 <- ee$FeatureCollection(assetId)
  expect_s3_class(object = ee_sf_01,
                  class =  "ee.featurecollection.FeatureCollection")
})


test_that("gcs_to_ee_image ", {
  # Get the filename of a image
  tif <- system.file("tif/L7_ETMs.tif", package = "stars")
  x <- read_stars(tif)
  st_crs(x) <- 4326
  assetId <- sprintf("%s/%s",ee_get_assethome(),'stars_l7')

  # Method 1
  # 1. Move from local to gcs
  gs_uri <- local_to_gcs(x = tif, bucket = 'rgee_dev')

  # 2. Pass from gcs to asset
  result <- gcs_to_ee_image(
    x = x,
    overwrite = TRUE,
    gs_uri = gs_uri,
    assetId = assetId
  )
  expect_equal(result,"users/datacolecfbf/stars_l7")
})
