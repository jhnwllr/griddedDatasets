
library(rgbif)
library(dplyr) 
library(stringr)

# Function to compute nearest neighbor features for a new download
# D - input data from a GBIF download
# key - focal key 
# k - number of nearest neighbors to compute 

getNNFeature = function(D,key,k) { # nearest neighbor features 
	
	# Subset data by focal key 
	D = D %>% filter(datasetKey == key)

	
	# Nearest Neighbor Percent Feature 
	NN = FNN::get.knn(cbind(D$decimalLongitude,D$decimalLatitude), k=k)$nn.dist # nearest neighbors
	
	# Set minimum distance 
	minimum = 0.01
	
	NN = round(NN,2) # round nearest neighbors nearest 0.01
	# NN = plyr::round_any(NN,0.01,ceiling) # adjust precision of rounding 
	
	TL = apply(NN,2,table) # table list
	boolL = lapply(TL,function(x) as.numeric(names(x)) > minimum) # distances less than minimum 
	T = list(); for(i in 1:length(TL)) T[[i]] = TL[[i]][boolL[[i]]] # filter out those distances less than minimum
	
	NNC = sapply(T,function(x) rev(sort(x))[1]) # NN point count
	NNPF = sapply(T,function(x) rev(sort(x))[1]/sum(x)) # NN percent feature. 

	# Other features 
	MCD = as.numeric(names(NNPF)) # most common distances of 4 NN 
	NNPLM = apply(NN,2,function(x) sum(x <= minimum))/nrow(NN)  # percent less than minimum

	NNF = cbind(
		rbind(NNC) %>% as.data.frame() %>% setNames(paste0("NNC",1:k)),
		rbind(NNPF) %>% as.data.frame() %>% setNames(paste0("NNPF",1:k)),
		rbind(MCD) %>% as.data.frame() %>% setNames(paste0("MCD",1:k)),
		rbind(NNPLM) %>% as.data.frame() %>% setNames(paste0("NNPLM",1:k))
	)

	NNF$key = key # add key 
	NNF$uniqueLatLon = nrow(D)

	return(NNF) # return the nearest neighbor feature 
} 

computeFeatures = function(saveDir) {

	load(paste0(saveDir,"gbifDatasets1000Sampled.rda")) # named D 

	# keys to continue processing. I chose over 20 unique lat-long points.
	keysToKeep = count(D,datasetKey) %>% as.data.frame() %>% filter(nn > 20) %>% pull(datasetKey) 
	
	# filter gbifDatasets1000Sampled.rda 
	D = D %>% filter(datasetKey %in% keysToKeep)
	# get unique keys 
	keys = D %>% pull(datasetKey) %>% unique()

	FL = list() # feature list
	for(key in keys) {
		out=try(getNNFeature(D,key,k=4))
			if(class(out) == "try-error") next # sometimes this feature fails because there are no points with NN dist greater than 0.01
		FL[[key]] = out
	}

	F = plyr::rbind.fill(FL) # combine features
	F = F %>% na.omit()

	F = F %>% select(key,NNPF1,MCD1,NNC1,uniqueLatLon) %>% setNames(c("datasetKey","percentNN","distanceNN","countNN","uniqueLatLon"))

	F$lastUpdated = Sys.Date()
	F$numberSampled = 1000

	load(paste0(saveDir,"datasetData.rda"))
	griddedDataSets = datasetData %>% select(datasetKey,publishingCountry,occCount,datasetTitle) %>% merge(F,id="datasetKey")

	# save(griddedDataSets,file ="C:/Users/ftw712/Desktop/griddedDataSets.rda")
	
}



