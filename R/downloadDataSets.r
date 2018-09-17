library(dplyr)
library(stringr)
library(foreach)
library(doParallel)


# Rscript "C:\Users\ftw712\Desktop\ebv\grids\classifyGBIF\R\classifyGBIF.r"
# Usually I run this seperately can fail often. 
# Can be run in parallel but will fail at the end. 

downloadDataSets = function(saveDir) { # download at minimum 1000 records from each dataset 

	load(paste0(saveDir,"datasetData.rda"))
	D = datasetData

	# do not download what we already have. In case script fails 
	doneKeys = list.files(paste0(saveDir,"datasetOcc/")) %>% str_replace_all(".rda","")
	keys = D %>% pull(datasetKey) 
	keys = keys[!keys %in% doneKeys]

	numberCores = 3 

	keyList = split(keys,ceiling(seq_along(keys)/ceiling(length(keys)/numberCores)))


	cl = makeCluster(numberCores)
	registerDoParallel(cl)

	# Download everything in parallel 
	L = foreach(i=1:numberCores,packages=c("dplyr","magrittr")) %dopar% { # output foreach into list 
		keys = keyList[[i]]

		for(key in keys) { # download 1000 samples from all datasets 
			occRecords = rgbif::occ_data(datasetKey=key,hasGeospatialIssue=FALSE,hasCoordinate=TRUE,limit=1000)$data

			if(!"decimalLongitude" %in% colnames(occRecords)) {print("failed");print(key); next }
			occRecords = occRecords %>% select(decimalLatitude,decimalLongitude) %>% 
			count(decimalLongitude,decimalLatitude) %>% as.data.frame()
			# if(class(OccRecords) == "try-error") next
			save(occRecords,file=paste0(saveDir,"datasetOcc/",key,".rda"))
		}
	}

}

