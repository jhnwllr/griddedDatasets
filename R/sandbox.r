
if(FALSE) { # run gridfinder 

library(gbifgridded)
library(dplyr)
library(purrr)

# large file of unique points for each datasetkey
file = "C:/Users/ftw712/Desktop/griddedDatasets/data/uniquePointsDatasetkey.csv"
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

# print(D)

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
# save(griddedDatasets,file="C:/Users/ftw712/Desktop/griddedDatasets.rda")
# saveRDS(D,file="C:/Users/ftw712/Desktop/griddedDatasets.rda")

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

filterGriddedDatasets = function() { # get filtered datasets 

	D = gbifgridded::griddedDatasets %>% # load griddedDatasets.rda
	select(key,NNPF1,NNC1,MCD1,uniqueLatLon) %>%
	filter(NNC1 > 30) %>% # get with only a reasonable number of nn-distances that are the same
	filter(NNPF1 > 0.3) %>% # only with high percentage of points having same nn-distance
	filter(MCD1 > 0.02) %>% # get only with distance greater than minimum 0.01
	arrange(-NNPF1) %>% 
	rename(datasetkey = key,percentNN = NNPF1, countNN = NNC1, distanceNN = MCD1, uniqueLatLon = uniqueLatLon) 
	
	return(D)
}

library(dplyr)
library(purrr)
library(httr)
library(roperators)
library(jsonlite)

L = filterGriddedDatasets() %>% transpose() # turn data.frame into a list to feed into map createMachineTag
L = L[1:10]

user = "jwaller@gbif.org"
password = "#9SkdnAksiDkneksQosnVid88A"

authentication = list(user,password)
save(authentication, file = "C:/Users/ftw712/Desktop/authentication.rda")

L %>% map(~ createMachineTag(datasetkey = .x$datasetkey,
							api = "http://api.gbif-uat.org/v1/dataset/",
							namespace = "griddedDataSet.jwaller.gbif.org",
							name = "griddedDataset",
							value = .x[2:4],
							embedValueList=TRUE,
							user = user,
							password = password))

							
keysToDelete = gbifapi::gbifapi("http://api.gbif-uat.org/v1/dataset?machineTagNamespace=griddedDataSet.jwaller.gbif.org")$results %>%
map_chr(~.x$key) 

keysToDelete %>% map(~ deleteMachineTag(datasetkey=.x,
				api="http://api.gbif-uat.org/v1/dataset/",
				namespaceToDelete = "griddedDataSet.jwaller.gbif.org",
				user=user,
				password=password))
		

gbifapi::gbifapi("http://api.gbif-uat.org/v1/dataset?machineTagNamespace=griddedDataSet.jwaller.gbif.org")$results %>%
map_chr(~.x$key)



# L[[1]]$datasetkey
# L

# list(L$percentNN,L$countNN,L$distanceNN,L$uniqueLatLon)
# value



# namespaceToDelete = "griddedDataSet.jwaller.gbif.org"
if(FALSE) { 
}




# "http://api.gbif-uat.org/v1/dataset/75956ee6-1a2b-4fa3-b3e8-ccda64ce6c2d/machineTag/"

# "crawler.gbif.org"

# GET("http://api.gbif-uat.org/v1/dataset/75956ee6-1a2b-4fa3-b3e8-ccda64ce6c2d/machineTag") %>% content()


# r

# L[[16]]$value %>% fromJSON()

# content_type("application/json"))
# machineTag %>% toJSON()
# r %>% content()
# machineTag = '{"namespace":"griddedDataSet.jwaller.gbif.org","name":"griddedDataSet","value":"{"-90.0","90.0"}"}'	  
# "value": {"minLatitude": -90.0, "maxLatitude": 90.0,"minLongitude": -180.0}
# r



# httr::GET(url) %>% content()

# api
# httr::POST(

# D %>% na.omit() %>% pull(NNPF1)

# key = "75956ee6-1a2b-4fa3-b3e8-ccda64ce6c2d"
# keys

# httr::GET("http://api.gbif.org/v1/dataset/75956ee6-1a2b-4fa3-b3e8-ccda64ce6c2d") %>% content()
# which(key == keys)

# indexList = unique(keys)[1:10] %>% map(~which(keys == .x))

 # %>% map_dbl(~ length(.x))


# str(D)

# rename(decimallatitude= decimalLatitude

# getNNFeature(D,key=key,k=4)

# indices 

# %>% min()
# indices[[1]] %>% max()




