
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
save(griddedDatasets,file= saveDir %+% "griddedDatasets.rda")
}

createMachineTag = function(datasetkey,api,namespace,name,value,embedValueList=TRUE,user,password) { # create a machineTag

	if(embedValueList) value = value %>% jsonlite::toJSON(auto_unbox=TRUE) # use this to embed json into a string

	machineTag = list(namespace=namespace,name=name,value=value) # create list for machine tag 

	url = api %+% datasetkey %+% "/machineTag"
	# need to encode json so that the list gets translated into json 
	response = httr::POST(url,authenticate(user,password),body=machineTag,encode="json") # post request to gbif api
	
	print(url)
	print(datasetkey)
	print(http_status(response)$category) # print if was successful 
	return(http_status(response)$category)
}

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

filterGriddedDatasets = function(file) { # get filtered datasets 
		
	# gbifgridded::griddedDatasets	
	D = readRDS(file) %>% # load griddedDatasets.rda
	select(key,NNPF1,NNC1,MCD1,uniqueLatLon) %>%
	filter(NNC1 > 30) %>% # get with only a reasonable number of nn-distances that are the same
	filter(NNPF1 > 0.3) %>% # only with high percentage of points having same nn-distance
	filter(MCD1 > 0.02) %>% # get only with distance greater than minimum 0.01
	arrange(-NNPF1) %>% 
	rename(datasetkey = key,percentNN = NNPF1, countNN = NNC1, distanceNN = MCD1, uniqueLatLon = uniqueLatLon) 
	
	return(D)
}

updateAllGriddedMachineTags = function(authentication) { 

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


file = "C:/Users/ftw712/Desktop/griddedDatasets/data/uniquePointsDatasetkey.csv"

library(dplyr)
library(purrr)
library(httr)
library(roperators)
library(jsonlite)

load("C:/Users/ftw712/Desktop/griddedDatasets/authentication.rda")

updateAllGriddedMachineTags(authentication)
# deleteAllGriddedMachineTags(authentication)



