
// hive -e 'SELECT count(*) as uniquePointCounts, decimallatitude, decimallongitude, datasetkey FROM uat.occurrence_hdfs GROUP BY decimallatitude, decimallongitude, datasetkey ORDER BY datasetkey' > uniquePointsDatasetkey.csv


val sqlContext = new org.apache.spark.sql.SQLContext(sc)
import sqlContext.implicits._;

// Get all unique points by datasetkey 
val SQL_OCCURRENCE = 
"""
SELECT count(*) as uniquePointCounts,
decimallatitude, 
decimallongitude, 
datasetkey 
FROM prod_h.occurrence 
GROUP BY decimallatitude, 
decimallongitude, 
datasetkey 
ORDER BY datasetkey
"""

val df_export = sqlContext.sql(SQL_OCCURRENCE). // filter known not gridded large datasets
filter($"datasetkey" =!= "4fa7b334-ce0d-4e88-aaae-2e0c138d049e"). // eBird
filter($"datasetkey" =!= "38b4c89f-584c-41bb-bd8f-cd1def33e92f"). // Artportalen
filter($"datasetkey" =!= "95db4db8-f762-11e1-a439-00145eb45e9a"). // DOF
filter($"datasetkey" =!= "b124e1e0-4755-430f-9eab-894f25a9b59c"). // Norwegian Species Observation Service
filter($"datasetkey" =!= "50c9509d-22c7-4a22-a47d-8c48425ef4a7"). // iNaturalist
na.drop()


import org.apache.spark.sql.SaveMode
import sys.process._

val save_table_name = "unique_points_datasetkey"

df_export.
write.format("csv").
option("sep", "\t").
option("header", "false").
mode(SaveMode.Overwrite).
save(save_table_name)

// export and copy file to right location 
(s"hdfs dfs -ls")!
(s"rm " + save_table_name)!
(s"hdfs dfs -getmerge /user/jwaller/"+ save_table_name + " " + save_table_name)!
(s"head " + save_table_name)!
val header = "1i " + df_export.columns.toSeq.mkString("""\t""")
Seq("sed","-i",header,save_table_name).!
(s"rm /mnt/auto/misc/download.gbif.org/custom_download/jwaller/" + save_table_name)!
(s"ls -lh /mnt/auto/misc/download.gbif.org/custom_download/jwaller/")!
(s"cp /home/jwaller/" + save_table_name + " /mnt/auto/misc/download.gbif.org/custom_download/jwaller/" + save_table_name)!

