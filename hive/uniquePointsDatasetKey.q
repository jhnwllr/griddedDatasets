-- get unique points by datasetkey
-- ORDER BY datasetkey is important allows us to read file more easily 

hive -e 'SELECT count(*) as uniquePointCounts, decimallatitude, decimallongitude, datasetkey FROM uat.occurrence_hdfs GROUP BY decimallatitude, decimallongitude, datasetkey ORDER BY datasetkey' > uniquePointsDatasetkey.csv

'SELECT count(DISTINCT decimallatitude, decimallongitude, datasetkey) FROM occurrence_hdfs' 





