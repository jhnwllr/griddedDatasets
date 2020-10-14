
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

# createMachineTag(datasetkey = .x$datasetkey,
# api = api,
# namespace = "griddedDataSet.jwaller.gbif.org",
# name = "griddedDataset",
# value = .x[2:4],
# embedValueList=TRUE,
# user = authentication$user,
# password = authentication$password))


# %>% transpose()

updateAllGriddedMachineTags = function(saveDir,authentication) {


L = filterGriddedDatasets(saveDir) %>% transpose() # turn data.frame into a list to feed into map createMachineTag

# api = "http://api.gbif-dev.org/v1/dataset/" # dev
# api_uat = "http://api.gbif-uat.org/v1/dataset/" # uat
api = "http://api.gbif.org/v1/dataset/" # prod

L %>% map(~ 
createMachineTag(datasetkey = .x$datasetkey,
api = api,
namespace = "griddedDataSet.jwaller.gbif.org",
name = "griddedDataset",
value = .x[2:4],
embedValueList=TRUE,
user = authentication$user,
password = authentication$password))

}




if(FALSE) { # check results against previous R version 

library(gbifMachineTagger)
library(dplyr)
library(purrr)

# df_tagged = getMachineTagData("griddedDataSet.jwaller.gbif.org") %>% 
# jsonValuesToColumns() %>%  
# tidyr::unnest() %>% 
# glimpse() %>% 
# saveRDS("C:/Users/ftw712/Desktop/df_tagged.rda")

df_tagged = readRDS("C:/Users/ftw712/Desktop/df_tagged.rda")

# filter(min_dist_count > 30) %>% # get with only a reasonable number of nn-distances that are the same
df_spark = data.table::fread("C:/Users/ftw712/Desktop/gbif_gridded_datasets_spark/data/gridded_datasets.tsv") %>% 
filter(percent >= 0.3) %>% # only with high percentage of points having same nn-distance
filter(min_dist > 0.02) %>% # get only with distance greater than minimum 0.01
filter(min_dist_count > 30) %>% 
mutate(min_dist_5 = min_dist) %>%
mutate(percent_5 = percent) %>%
select(datasetkey,min_dist_5,percent_5) %>%
glimpse() 

spark = df_spark$datasetkey %>% unique()
tagged = df_tagged$datasetkey

# spark[!spark %in% tagged]
# tagged[tagged %in% spark]
tagged[!tagged %in% spark]


# df_spark = data.table::fread("C:/Users/ftw712/Desktop/gbif_gridded_datasets_spark/data/gridded_datasets.tsv") %>% 
# filter(percent >= 0.3) %>% # only with high percentage of points having same nn-distance
# filter(min_dist > 0.02) %>% # get only with distance greater than minimum 0.01
# filter(min_dist_count > 30) %>% 
# glimpse() 

# ds = merge(df_spark_5000,df_spark,id="datasetkey",all.x=TRUE) %>%
# select(datasetkey,min_dist,percent,min_dist_5,percent_5) %>% 
# mutate(ptg = datasetkey %in% df_tagged$datasetkey) %>% 
# select(-ptg)

# filter(ptg) %>%
# ds


# %>%
# glimpse()


# df_spark %>% filter(datasetkey == "e6fab7b3-c733-40b9-8df3-2a03e49532c1")
# filter(min_dist_count > 30) %>% # get with only a reasonable number of nn-distances that are the same

# merge(df_spark_5000,df_tagged,id="datasetkey",all=TRUE) %>% 
# glimpse() %>% 
# select(datasetkey,min_dist,percent,distanceNN,countNN) %>% 
# filter(is.na(distanceNN))


# df_tagged %>% glimpse()

# sort(df_spark$total_count)

# d
# d %>% filter(datasetkey == "85ab1bf8-f762-11e1-a439-00145eb45e9a")

# {"percentNN":0.9951,"countNN":608,"distanceNN":0.04}

}
