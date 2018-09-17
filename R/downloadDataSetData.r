library(dplyr)
library(rgbif)

# downloads dataset data for all occurrence datasets 

downloadDataSetData = function(saveDir) {
	
	N = 15 # for 15k datasets 
	
	DL = list()
	for(i in 0:N) { # 15 for around 15K occurrence datasets 
		DL[[i+1]] = rgbif::dataset_search(limit=1000,start=1000*i,type="occurrence")$data %>% as.data.frame()
	}

	D = plyr::rbind.fill(DL)

	keys = D %>% pull(datasetKey)
	D$occCount = sapply(keys, function(x) rgbif::occ_count(datasetKey = x))
	str(D)
	datasetData = D
	
	save(datasetData,file=paste0(saveDir,"datasetData.rda")

}
