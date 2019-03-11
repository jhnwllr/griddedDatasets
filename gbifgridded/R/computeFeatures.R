#' Add taxon info to a data.frame.
#'
#' @param .data data.frame to be passed in probably through a pipe %>%
#' @param key unquoted column name for taxonkeys to be passed in
#' @return Returns data.frame of results.
#' @examples
#'
#'\dontrun{
#'
#' D %>% addTaxonInfo(specieskey)
#'
#'}
#'

computeFeatures = function(file,saveDir = "C:/Users/ftw712/Desktop/") {

  # large file of unique points for each datasetkey
  keysToSkip = c("4fa7b334-ce0d-4e88-aaae-2e0c138d049e")

  getIndexList = function(file) { # get indices so that we can only read in the correct
    keys = data.table::fread(file,select="V4",fill=TRUE) %>%
      as.data.frame() %>%
      rename(datasetkey=V4)
    indexList = keys %>% group_by(datasetkey) %>% attr("indices")
  }

  indexList = getIndexList(file)

  DL = list()
  for(i in 1:length(indexList)) {

    print(i)
    index = indexList[[i]]
    out = data.frame(key=NA) # default if dataset needs to be skipped

    if(length(index) > 20) { # only compute features if unique points in dataset more than 20

      colNames = c("count","decimalLatitude","decimalLongitude","datasetKey")

      D = data.table::fread(file,skip=min(index),nrows=length(index),fill=TRUE) %>%
        as.data.frame() %>%
        setNames(colNames) %>%
        mutate(decimalLatitude = as.numeric(as.character(decimalLatitude))) %>%
        mutate(decimalLongitude = as.numeric(as.character(decimalLongitude))) %>%
        na.omit()

      key = D %>% pull(datasetKey) %>% unique()

      out = try(gbifgridded::getNNFeature(D,key,k=4))
      if(class(out) == "try-error") out = data.frame(key=NA) #
    }

    print(out)
    DL[[i]] = out

  }

  D = plyr::rbind.fill(DL) %>%
    na.omit()

  griddedDatasets = D
  saveRDS(griddedDatasets,file= saveDir %+% "griddedDatasets.rda")
}
