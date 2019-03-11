
filterGriddedDatasets = function(saveDir) { # get filtered datasets

  # gbifgridded::griddedDatasets
  D = readRDS(saveDir %+% "griddedDatasets.rda") %>% # load griddedDatasets.rda
    select(key,NNPF1,NNC1,MCD1,uniqueLatLon) %>%
    filter(NNC1 > 30) %>% # get with only a reasonable number of nn-distances that are the same
    filter(NNPF1 > 0.3) %>% # only with high percentage of points having same nn-distance
    filter(MCD1 > 0.02) %>% # get only with distance greater than minimum 0.01
    arrange(-NNPF1) %>%
    rename(datasetkey = key,percentNN = NNPF1, countNN = NNC1, distanceNN = MCD1, uniqueLatLon = uniqueLatLon)

  return(D)
}


updateAllGriddedMachineTags = function(saveDir,authentication) {


  L = filterGriddedDatasets(saveDir) %>% transpose() # turn data.frame into a list to feed into map createMachineTag

  # api_uat = "http://api.gbif-uat.org/v1/dataset/"
  api = "http://api.gbif.org/v1/dataset/"

  L %>% map(~ createMachineTag(datasetkey = .x$datasetkey,
                               api = api,
                               namespace = "griddedDataSet.jwaller.gbif.org",
                               name = "griddedDataset",
                               value = .x[2:4],
                               embedValueList=TRUE,
                               user = authentication$user,
                               password = authentication$password))

}
