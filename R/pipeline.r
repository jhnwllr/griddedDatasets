
# pipeline to classify all 15k datasets in gbif to create griddedDataSets.csv
# might need to set up the proper directory structure for this to work. 

saveDir = "C:/Users/ftw712/Desktop/ebv/grids/classifyGBIF/data/"

# 1. Download all dataset data. 
# Used for downloading all datasets below and used for dataset meta data. 
downloadDataSetData(saveDir)

# 2. Download all 15k occurrence datasets 
# Usually I run this seperately can fail often. Can take several hours 
downloadDataSets(saveDir)

# 3. Simply combine all datasets into a single data.frame. 
combineDataSets(saveDir)

# 4. compute nearest neighbor features and save griddedDataSets.csv
computeFeatures(saveDir)


