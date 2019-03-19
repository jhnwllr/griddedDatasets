
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


if(FALSE) { # get all machineTags 

library(dplyr)
library(purrr)
library(roperators)

# getMachineTagKeys = function(limit=1000,machineTagNamespace="griddedDataSet.jwaller.gbif.org") { 

getGriddedKeys = function(minDistance = 0.01, minCount = 0, minPercent = 0, limit=1000) { 

	datasetkeys = httr::GET("http://api.gbif.org/v1/dataset?machineTagNamespace=griddedDataSet.jwaller.gbif.org&limit=" %+% limit) %>% 
	httr::content() %>%
	purrr::pluck("results") %>% # used to access elements in list 
	map_chr(~ .x$key) # get the content of the api call 

	L = httr::GET("http://api.gbif.org/v1/dataset?machineTagNamespace=griddedDataSet.jwaller.gbif.org&limit=" %+% limit) %>% 
	httr::content() %>% # get the content of the api call 
	purrr::pluck("results") %>% # used to access elements in list 
	map(~ .x$machineTags) %>% 
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


}


if(FALSE) { 
library(dplyr)
library(purrr)
library(roperators)
library(tibble)

limit=1000
datasetkeys = httr::GET("http://api.gbif.org/v1/dataset?machineTagNamespace=griddedDataSet.jwaller.gbif.org&limit=" %+% limit) %>% 
httr::content() %>%
purrr::pluck("results") %>% # used to access elements in list 
map_chr(~ .x$key) # get the content of the api call 

L = httr::GET("http://api.gbif.org/v1/dataset?machineTagNamespace=griddedDataSet.jwaller.gbif.org&limit=" %+% limit) %>% 
httr::content() %>% # get the content of the api call 
purrr::pluck("results") %>% # used to access elements in list 
map(~ .x$machineTags) %>% 
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

# %>% 
# as.data.frame()

D$distanceNN %>% flatten_dbl() %>% table() %>% sort()
}

if(FALSE) { # example 
library(rgbif)
library(dplyr) 

# taxon key for Syntrichia norvegica Weber, 1804 (a moss)
taxonKey=2671266

occData <- occ_data(taxonKey=taxonKey,
country="SE", # get only from SWEDEN to limit results
hasGeospatialIssue=FALSE, # remove those with other geospatial issues 
hasCoordinate=TRUE, # get only with coordinates
limit=1000)$data # get first 1000 records

# only get dataset keys with spacing greater than around 10 km
keysToFilter <- gbifgridded::getGriddedKeys(minDistance = 0.1) 

nrow(occData)

cleanData <- occData %>% # should be around 140 occurrence records
filter(!datasetKey %in% keysToFilter) 

nrow(cleanData) # should remove around 50 low resolution points
}


# compare with cd_round

library(CoordinateCleaner)
library(dplyr)

file = "C:/Users/ftw712/Desktop/griddedDatasets/data/uniquePointsDatasetkey.csv"


getIndexList = function(file) { # get indices so that we can only read in the correct 
	keys = data.table::fread(file,select="V4",fill=TRUE) %>% 
	as.data.frame() %>% 
	rename(datasetkey=V4) 
	indexList = keys %>% group_by(datasetkey) %>% attr("indices")
}

indexList = getIndexList(file)


DL = list()
# for(i in 1:length(indexList)) { 
for(i in 1:15) { 

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

out = try(CoordinateCleaner::cd_round(D, lon = "decimalLongitude", lat = "decimalLatitude", ds = "datasetKey",graphs=FALSE,value="dataset",reg_dist_min =0.01))
if(class(out) == "try-error") out = data.frame(dataset=NA) # 


}

DL[[i]] = out 
}

DL







# 



# 22 + 466

# distanceNN
# class(D)
# str(D)
# D$distanceNN
# table(D$distanceNN)

# table(D$distanceNN)
	# gbifgridded::getGriddedKeys()


# L
# publishingOrganizationKey = L %>% pluck("publishingOrganizationKey")
# publishingOrganizationKey

# "http://api.gbif.org/v1/publisher/publisher/471aeb39-799a-44c5-9824-dfe65413b83c"
# https://www.gbif.org/api/dataset/search?limit=0&publishing_org=471aeb39-799a-44c5-9824-dfe65413b83c
# httr::GET("http://api.gbif.org/v1/publisher/" %+% publishingOrganizationKey) %>% 
# httr::content()

# L

# L %>% pluck("title")


# "http://api.gbif.org/v1/dataset/?publishingOrg=1928bdf0-f5d2-11dc-8c12-b8a03c50a862"

# "?publishingOrg=1928bdf0-f5d2-11dc-8c12-b8a03c50a862"


# comparision with cd_round 

  # datasettitle = keys %>%
    # map(~ gbifapi::gbifapi("http://api.gbif.org/v1/dataset/" %+% .x)$title) %>%
    # map_if(is_empty, ~ NA_character_) %>%
    # flatten_chr()


# keys to remove 
# if(FALSE) {
# }

# %>% 





# tidyr::unnest() %>%
# tidyr::spread()
# %>% 
# tibble::rownames_to_column()



# values = L %>% map(~ .x$machineTags) %>%
# flatten() %>%
# map(~ .x$value)

# data.frame(values,

# [[10]]$machineTags[[2]]$value

	
# purrr::map_chr(~.x$key) # grab the datasetkey and put into character vector
# return(keys)
	


# getGriddedDataSetKeys(limit=1000)	
	
	# get a big list of keys

	# keys = L$results %>% purrr::map_chr(~.x$key) # get all the keys as character
	# return(keys)
	# }


# keys