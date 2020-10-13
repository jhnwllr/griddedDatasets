

library(gbifgridded)
library(dplyr)

file = "uniquePointsDatasetkey.csv"  
saveDir = "C:/Users/ftw712/Desktop/" # where to save griddedDatasets.rda

# computeFeatures(file,saveDir) # will page through uniquePointsDatasetkey.csv file by dataset to compute NN-features

load("C:/Users/ftw712/Desktop/griddedDatasets/authentication.rda") # needed to update 

# deleteAllGriddedMachineTags(authentication)
# updateAllGriddedMachineTags(saveDir,authentication)

gbifgridded::getGriddedData(minDistance = 0, minPercent = 0) %>%
glimpse() %>%
readr::write_tsv(path="C:/Users/ftw712/Desktop/griddedDatasets/csv/griddedDatasets.tsv")

# scp -r /cygdrive/c/Users/ftw712/Desktop/griddedDatasets/csv/griddedDatasets.tsv jwaller@c5gateway-vh.gbif.org:/home/jwaller/





