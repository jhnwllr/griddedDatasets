
// get coordinate uncertainty meters 

import org.apache.spark.sql.functions._;

val sqlContext = new org.apache.spark.sql.SQLContext(sc);
import sqlContext.implicits._;

val df_gridded = spark.read.
option("sep", "\t").
option("header", "true").
option("inferSchema", "true").
csv("griddedDatasets.tsv")

val df_occ = sqlContext.sql("SELECT * FROM prod_h.occurrence").
select(
"datasetkey",
"coordinateuncertaintyinmeters",
"footprintwkt",
"coordinateprecision",
"v_geodeticdatum"
).
groupBy("datasetkey").
agg(countDistinct("coordinateuncertaintyinmeters").as("unique_meters"),countDistinct("footprintwkt").as("unique_wkt"),countDistinct("coordinateprecision").as("unique_cp"),countDistinct("v_geodeticdatum").as("unique_datum"))


// coordinateprecision

// round to nearest 5000 meters 
val df = df_gridded.join(df_occ,"datasetkey").filter(col("countNN").isNotNull).filter($"unique_meters" === 0 && $"unique_wkt" === 0 && $"unique_datum" === 0 && $"unique_cp" === 0).orderBy(desc("percentNN")).
withColumn("distance_in_meters",($"distanceNN"/0.01)*(1.11*1000)/2). 
withColumn("distance_in_meters_rounded", round(col("distance_in_meters")*1 / 5000) * 5000 / 1)



// default-term.gbif.org



orderBy($"datasetkey",desc("coordinateuncertaintyinmeters")).
filter(col("coordinateuncertaintyinmeters").isNull).filter(col("footprintwkt").isNull)

