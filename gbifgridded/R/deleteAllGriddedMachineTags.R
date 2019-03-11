deleteAllGriddedMachineTags = function(authentication) {
  api = "http://api.gbif.org/v1/dataset/"

  keysToDelete = gbifapi::getGriddedDataSetKeys()

  keysToDelete %>% map(~ deleteMachineTag(datasetkey=.x,
                                          api=api,
                                          namespaceToDelete = "griddedDataSet.jwaller.gbif.org",
                                          user=authentication$user,
                                          password=authentication$password))

  print(gbifapi::getGriddedDataSetKeys()) # should be empty at the end
}
