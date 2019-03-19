#' Get GBIF datasetkeys that are rasterized/gridded/equally-spaced
#'
#' Gets all the gridded uuid datasetkeys from the GBIF.org registry that pass certain filters.
#'
#' @param minDistance Filters by the minimum distance in decimal degrees of the most common nn-distance. Default is 0.
#' @param minCount Filters by the minimum number of points that have the same nn-distance. Default is 0.
#' @param minPercent Filters by the  minimum percentage of occurrence points with the same nn-distance. Default is 0.
#' @param limit the maximum number of datasetkeys to return. Default is 1000. There are only around 600 gridded datasets on GBIF.org.
#' @return Returns a vector of uuid datasetkeys
#' @references \url{https://data-blog.gbif.org/post/finding-gridded-datasets/}
#' @examples
#'
#'\dontrun{
#'
#' library(rgbif)
#' library(dplyr)
#' # taxon key for Syntrichia norvegica Weber, 1804 (a moss)
#' taxonKey=2671266
#' # Get occurrence data for a moss occurring in SWEDEN
#' occData <- occ_data(taxonKey=taxonKey,
#'                    country="SE", # get only from SWEDEN to limit results
#'                    hasGeospatialIssue=FALSE, # remove those with other geospatial issues
#'                    hasCoordinate=TRUE, # get only with coordinates
#'                    limit=1000)$data # get first 1000 records
#' # only get dataset keys with spacing greater than around 10 km
#' keysToFilter <- gbifgridded::getGriddedKeys(minDistance = 0.1)
#' nrow(occData)
#' cleanData <- occData %>% # should be around 140 occurrence records
#'  filter(!datasetKey %in% keysToFilter)
#' nrow(cleanData) # should remove around 50 low resolution occurrences
#'
#'}
#'

getGriddedKeys = function(minDistance = 0, minCount = 0, minPercent = 0, limit=1000) {

  datasetkeys = httr::GET("http://api.gbif.org/v1/dataset?machineTagNamespace=griddedDataSet.jwaller.gbif.org&limit=" %+% limit) %>%
    httr::content() %>%
    purrr::pluck("results") %>% # used to access elements in list
    purrr::map_chr(~ .x$key) # get the content of the api call

  L = httr::GET("http://api.gbif.org/v1/dataset?machineTagNamespace=griddedDataSet.jwaller.gbif.org&limit=" %+% limit) %>%
    httr::content() %>% # get the content of the api call
    purrr::pluck("results") %>% # used to access elements in list
    purrr::map(~ .x$machineTags) %>%
    purrr::flatten() # got down one layer in a list

  namespace = L %>% map_chr(~ .x$namespace)
  value = L %>% map_chr(~ .x$value)

  D = tibble(value=value,namespace=namespace) %>%
    filter(namespace == "griddedDataSet.jwaller.gbif.org")

  # translate the embeded json into a data.frame
  D = D %>% pull(value) %>%
    map(~ jsonlite::fromJSON(.x)) %>% # convert JSON string into R list
    map(~ tibble::enframe(.x)) %>% # convert into tibble
    map(~ tidyr::spread(.x,name,value)) %>% # rearrange tibble
    plyr::rbind.fill() %>% # combine all the results
    mutate(datasetkey = datasetkeys)

  # begin filtering to get keysToFilter
  keysToFilter = D %>%
    filter(distanceNN > !!minDistance) %>%
    filter(distanceNN > !!minCount) %>%
    filter(distanceNN > !!minPercent) %>%
    pull(datasetkey)

  return(keysToFilter)
}
