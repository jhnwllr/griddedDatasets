# Repository for updating griddedDataSet.jwaller.gbif.org Tags

Use these steps to update gridded dataset machine tags on GBIF https://www.gbif.org/. 

This work is based on a blog post found here:  https://data-blog.gbif.org/post/finding-gridded-datasets/

This api call will get you all the gridded datasets (griddedDataSet.jwaller.gbif.org) on gbif.org. 

```
http://api.gbif.org/v1/dataset?machineTagNamespace=griddedDataSet.jwaller.gbif.org&limit=1000

```

# Update all the machine tags.

These steps are only possible if you have access to the registry and some cluster with hive installed. 

## 1. Hive Part

Run this query on C4 or somewhere with access to hive and occurrence_hdfs to get all unique occurrence points by datasetkey. Should be less than 50 million occurrences and around 2 GB of data. 

```
hive -e 'SELECT count(*) as uniquePointCounts, decimallatitude, decimallongitude, datasetkey FROM uat.occurrence_hdfs GROUP BY decimallatitude, decimallongitude, datasetkey ORDER BY datasetkey' > uniquePointsDatasetkey.csv

```

## 2. R Part 

Install my R package gbifgridded.

```
devtools::install_github("jhnwllr/griddedDatasets", subdir="gbifgridded")

```

Run this to update all machineTags on GBIF. 

```
library(gbifgridded)

file = "uniquePointsDatasetkey.csv"" # use file from hive part above 
saveDir = "C:/Users/ftw712/Desktop/" # where to save griddedDatasets.rda

computeFeatures(file,saveDir) # will page through uniquePointsDatasetkey.csv file by dataset to compute NN-features

load("authentication.rda") # needed to update authentication = list(user="jwaller",password="yourpassword")

updateAllGriddedMachineTags(saveDir,authentication)

```

Run this to delete all gridded dataset machine tags. Should probably do this step first before running the first step. 

```
load("authentication.rda") # needed to update authentication = list(user="jwaller",password="yourpassword")

deleteAllGriddedMachineTags(authentication)

```

# Simple R script to work with the data from gridded dataset machine tag 

Use the following to get all datasetkeys with the minimum distance between unique occurrence points >0.5 and fraction >0.5. 

```
gbifgridded::getGriddedKeys(minDistance = 0.5, minPercent = 0.5) 

```



