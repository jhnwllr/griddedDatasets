# Repository for updating griddedDataSet.jwaller.gbif.org Tags

Use these steps to update gridded dataset machine tags on GBIF. 

This work is based on a blog post found here:  https://data-blog.gbif.org/post/finding-gridded-datasets/

This api call will get you all the gridded datasets (griddedDataSet.jwaller.gbif.org) on gbif.org. 

```
http://api.gbif.org/v1/dataset?machineTagNamespace=griddedDataSet.jwaller.gbif.org&limit=1000

```

# Update all the machine tags.

## 1. Hive Part

Run this query on C4 or somewhere with access to get all unique GBIF datapoints by datasetkey. Should be less than 50 million. 

```
hive -e 'SELECT count(*) as uniquePointCounts, decimallatitude, decimallongitude, datasetkey FROM uat.occurrence_hdfs GROUP BY decimallatitude, decimallongitude, datasetkey ORDER BY datasetkey' > uniquePointsDatasetkey.csv

```

## 2. R Part 

Install R package gbifgridded.

```
devtools::install_github("jhnwllr/griddedDatasets", subdir="gbifgridded")

```

Run this to update all machineTags on GBIF. 

```
library(gbifgridded)

file = uniquePointsDatasetkey.csv # use file from hive part above 
saveDir = "C:/Users/ftw712/Desktop/"

computeFeatures(file,saveDir) # will page through file by dataset to compute NN-features

load("authentication.rda") # needed to update authentication = list(user="jwaller",password="yourpassword")

updateAllGriddedMachineTags(saveDir,authentication)

# deleteAllGriddedMachineTags(authentication)

```

