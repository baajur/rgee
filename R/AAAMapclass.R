#' Class EarthEngineMap
#'
#' @slot object the spatial object
#' @slot map the leaflet map object
#'
#' @exportClass EarthEngineMap
setClass('EarthEngineMap',
         slots = c(object = 'list',
                   map = 'ANY'))
NULL

if ( !isGeneric('EarthEngineMap') ) {
  setGeneric('EarthEngineMap', function(x, ...)
    standardGeneric('EarthEngineMap'))
}
