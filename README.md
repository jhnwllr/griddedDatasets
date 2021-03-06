## Repository for updating griddedDataSet.jwaller.gbif.org Tags

Use these steps to update gridded dataset machine tags on GBIF https://www.gbif.org/. 

This work is based on a blog post found here:  https://data-blog.gbif.org/post/finding-gridded-datasets/

This api call will get you all the gridded datasets (griddedDataSet.jwaller.gbif.org) on gbif.org. 

```
http://api.gbif.org/v1/dataset?machineTagNamespace=griddedDataSet.jwaller.gbif.org&limit=1000

```

## spark-scala version for updating machine tags 

This port uses [Local Sensitivity Hashing](https://databricks.com/session/locality-sensitive-hashing-by-spark) in order to do nearest neighbor search with euclidean distances. Using some other search space optimizer might work better. 

It currently works on datasets that have less than around 50K-100K unique points.  The R version had the a similar limit. With max set at **50K uniques points** it runs in 13 minutes on the current GBIF cluster set up. 

**Build** 

```
cd \griddedDatasets\gbif_gridded_spark\
sbt package
```

**Copy** `gridded_datasets_2.11-0.1.jar` on to server.

```
scp -r /cygdrive/c/Users/ftw712/Desktop/gbif_gridded_spark/target/scala-2.11/gridded_datasets_2.11-0.1.jar jwaller@c5gateway-vh.gbif.org:/home/jwaller/
```

**Run** with `spark2-submit`

```
spark2-submit --num-executors 40 --executor-cores 5 --driver-memory 8g --driver-cores 4 --executor-memory 16g gridded_datasets_2.11-0.1.jar
```

This is produce a file called **gridded_datasets** in hdfs. 

**Export** file for download:  

```
import sys.process._

val save_table_name = "gridded_datasets"

val df_export = spark.read.
option("sep", "\t").
option("header", "true").
option("inferSchema", "true").
csv(save_table_name)

// export and copy file to right location 
(s"hdfs dfs -ls")!
(s"rm " + save_table_name)!
(s"hdfs dfs -getmerge /user/jwaller/"+ save_table_name + " " + save_table_name)!
(s"head " + save_table_name)!
// val header = "1i " + "specieskey\tspecies_occ_count\tdatasetkey\tdataset_occ_count\tdecimallatitude\tdecimallongitude\tgbifid\tbasisofrecord\tkingdom\tclass\tkingdomkey\tclasskey\teventdate\tdatasetname\tdate"
val header = "1i " + df_export.columns.toSeq.mkString("""\t""")
Seq("sed","-i",header,save_table_name).!
(s"rm /mnt/auto/misc/download.gbif.org/custom_download/jwaller/" + save_table_name)!
(s"ls -lh /mnt/auto/misc/download.gbif.org/custom_download/jwaller/")!
(s"cp /home/jwaller/" + save_table_name + " /mnt/auto/misc/download.gbif.org/custom_download/jwaller/" + save_table_name)!

```

Use [machineTagger](https://github.com/jhnwllr/gbifMachineTagger)

```
devtools::install_github("jhnwllr/gbifMachineTagger")

# update machine tags using machine tagger 
load("C:/Users/ftw712/Desktop/griddedDatasets/authentication.rda")

library(dplyr)
library(gbifMachineTagger)
library(purrr)

d = readr::read_tsv("http://download.gbif.org/custom_download/jwaller/gridded_datasets") %>% 
filter(percent >= 0.3) %>% # only with high percentage of points having same nn-distance
filter(min_dist > 0.02) %>% # get only with distance greater than minimum 0.01
filter(min_dist_count > 30) %>%
select(datasetkey,percentNN=percent,countNN=min_dist_count,distanceNN=min_dist,uniqueLatLon=total_count) %>%
glimpse()

L = d %>% transpose()

# api = "http://api.gbif-uat.org/v1/dataset/" # uat
api = "http://api.gbif.org/v1/dataset/" # prod

L %>% map(~ 
createMachineTag(
datasetkey=.x$datasetkey,
namespace="griddedDataSet.jwaller.gbif.org",
name="griddedDataset",
value=.x[2:4],
embedValueList=TRUE,
user = authentication$user,
password = authentication$password,
api=api)
)


```


## R version to update machine tags locally (largely deprecated)  


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

file = "C:/Users/ftw712/Desktop/griddedDatasets/data/uniquePointsDatasetkey.csv" # use file from part above 
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



