
# Finding Gridded Datasets in Scala-Spark

This is a port to spark-scala of my original gridded dataset finder in R. 

This port uses [Local Sensitivity Hashing](https://databricks.com/session/locality-sensitive-hashing-by-spark) in order to do nearest neighbor search with euclidean distances. Using some other search space optimizer might work better. 

It currently works on datasets that have less than around 50K-100K unique points.  The R version had the a similar limit. 


# Build 

```
cd 
sbt package
```

```
scp -r /cygdrive/c/Users/ftw712/Desktop/gbif_gridded_spark/target/scala-2.11/gridded_datasets_2.11-0.1.jar jwaller@c5gateway-vh.gbif.org:/home/jwaller/
```

```
spark2-submit --num-executors 40 --executor-cores 5 --driver-memory 8g --driver-cores 4 --executor-memory 16g gridded_datasets_2.11-0.1.jar
```

```
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
