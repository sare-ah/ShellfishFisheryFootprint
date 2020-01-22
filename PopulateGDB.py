############################################################################
# Name: PopulateGDB.py
#
# Description: Create a geodatabase and populate with feature classes
#   produced using the FisheryFootprint R script.
#   Create empty feature datasets and populate with feature classes
#   from the Shellfish spatial server.
#
# Date: January 19th, 2016
# Author: Sarah Davies
#         Sarah.Davies@dfo-mpo.gc.ca
#         250-756-7124     
############################################################################

# Import system modules
import arcpy
from arcpy import env

# 1. Create new file geodatabase
# Set local variables
out_folder_path = "C:/Users/daviessa/Documents/ArcGIS" 
out_name = "Shellfish_Fishery_Footprint.gdb"

# Execute CreateFileGDB
arcpy.CreateFileGDB_management(out_folder_path, out_name)

# 2. Convert all SHP in folder to GDB 
# Set environment settings
env.workspace = "C:/Users/daviessa/Documents/R/Habitat Mapping/Footprints"

# Set local variables
inFeatures = arcpy.ListFeatureClasses()
outLocation = "C:/Users/daviessa/Documents/ArcGIS/Shellfish_Fishery_Footprint.gdb"
 
# Execute TableToGeodatabase
arcpy.FeatureClassToGeodatabase_conversion(inFeatures, outLocation)

# 3. Create three feature datasets within the GDB
# Set local variables
out_dataset_path = "C:/Users/daviessa/Documents/ArcGIS/Shellfish_Fishery_Footprint.gdb" 
out_name1 = "GreenSeaUrchin"
out_name2 = "RedSeaUrchin"
out_name3 = "SeaCucumber"

# Creating a spatial reference object
sr = arcpy.SpatialReference("S:/SF_GIS_DB/Master/Green_Urchin_Fishing_Event/Current/gsufishingevent2014_15.prj")

# Execute CreateFeaturedataset 
arcpy.CreateFeatureDataset_management(out_dataset_path, out_name1, sr)
arcpy.CreateFeatureDataset_management(out_dataset_path, out_name2, sr)
arcpy.CreateFeatureDataset_management(out_dataset_path, out_name3, sr)

# 4. Copy shapefiles to feature datasets
# GreenSeaUrchin
# Set environment settings
env.workspace = "S:/SF_GIS_DB/Master/Green_Urchin_Fishing_Event/Current"
# Set local variables
inFeatures = arcpy.ListFeatureClasses()
outLocation = "C:/Users/daviessa/Documents/ArcGIS/Shellfish_Fishery_Footprint.gdb/GreenSeaUrchin"
# Execute TableToGeodatabase
arcpy.FeatureClassToGeodatabase_conversion(inFeatures, outLocation)

# RedSeaUrchin
# Set environment settings
env.workspace = "S:/SF_GIS_DB/Master/Red_Urchin_Fishing_Event/Current"
# Set local variables
inFeatures = arcpy.ListFeatureClasses()
outLocation = "C:/Users/daviessa/Documents/ArcGIS/Shellfish_Fishery_Footprint.gdb/RedSeaUrchin"
# Execute TableToGeodatabase
arcpy.FeatureClassToGeodatabase_conversion(inFeatures, outLocation)

# SeaCucumber
# Set environment settings
env.workspace = "S:/SF_GIS_DB/Master/Cucumber_Fishing_Event/Current"
# Set local variables
inFeatures = arcpy.ListFeatureClasses()
outLocation = "C:/Users/daviessa/Documents/ArcGIS/Shellfish_Fishery_Footprint.gdb/SeaCucumber"
# Execute TableToGeodatabase
arcpy.FeatureClassToGeodatabase_conversion(inFeatures, outLocation)
