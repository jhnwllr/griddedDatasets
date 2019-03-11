deleteMachineTag = function(datasetkey,api,namespaceToDelete,user,password) { # delete all machine tags with namespace

  url = api %+% datasetkey %+% "/machineTag"
  response = GET(url) %>% content()

  key = response %>% map_chr(~ .x$key)
  namespace = response %>% map_chr(~.x$namespace)

  keysToDelete = data.frame(key,namespace) %>%
    filter(!namespace == "crawler.gbif.org") %>% # never delete namespace crawler.gbif.org
    filter(namespace == !!namespaceToDelete) %>% # !! is dplyr speak for use this variable
    pull(key) %>%
    as.character()

  print(keysToDelete)
  print(namespace)
  responseList = keysToDelete %>% map(~ DELETE(api %+% datasetkey %+% "/machineTag/" %+% .x,authenticate(user,password)))
  print(responseList)
}
