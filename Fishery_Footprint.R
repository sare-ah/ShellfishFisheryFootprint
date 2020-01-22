####################################################################################################################
# Fishery Footprint
# 
# Objective:  Create a spatial layer of fishing events for various shellfish fishery            
#
# Summary:    For each fishery of interest - access logbook data, read fishing events, build shapefile
# 
# Fisheries:  Crab by trap, Euphausiid, Geoduck & Horseclam by dive, Goose barnacle, Octopus by dive, Octopus by trap, 
#             Opal squid, Prawn & shrimp by trap, Scallop by dive, Scallop by trawl, Shrimp trawl, Tanner crab
#
# Note:       32 bit R needed to read MS Access database
#             Working directory and location of databases are hard coded into the script
#             Script builds SHP, currently R cannot write to GDB
#
# Author:     Sarah Davies
#             Sarah.Davies@dfo-mpo.gc.ca
#             250-756-7124
# Date:       January, 2016
###################################################################################################################

###################
### Start Fresh ###
###################

rm(list=ls())

getwd()
setwd("W:/Fishery_data/Shellfish Fishery Footprint/Shapefiles")

Sys.getenv("R_ARCH")   
# "/i386" 32 bit R --- which is necessary to grab data from MS Access database
# "/64"   64 bit R

# Install missing packages and load required packages (if required)
UsePackages <- function( pkgs, update=FALSE, locn="http://cran.rstudio.com/" ) {
  # Identify missing (i.e., not yet installed) packages
  newPkgs <- pkgs[!(pkgs %in% installed.packages( )[, "Package"])]
  # Install missing packages if required
  if( length(newPkgs) )  install.packages( newPkgs, repos=locn )
  # Loop over all packages
  for( i in 1:length(pkgs) ) {
    # Load required packages using 'library'
    eval( parse(text=paste("library(", pkgs[i], ")", sep="")) )
  }  # End i loop over package names
  # Update packages if requested
  if( update ) update.packages( ask=FALSE )
}  # End UsePackages function

# Make packages available
UsePackages( pkgs=c("RODBC","rgdal","sp", "dplyr", "sqldf", "maptools") ) 

#################
### Functions ###
#################

# Grab the fishing events
GrabFishingDat <- function( db, logs ) {
  # Extract the data base extension
  dbExt <- strsplit( x=basename(db), split=".", fixed=TRUE )[[1]][2]
  # Connect to the data base depending on the extension
  if( dbExt == "mdb" )  dataBase <- odbcConnectAccess( access.file=db )
  if( dbExt == "accdb" )  dataBase <- odbcConnectAccess2007( access.file=db )
  # Grab the logbook data
  fe <- sqlFetch( channel=dataBase, sqtable=logs )
  # Message re logservation data
  cat( "Imported logbook table with", nrow(fe), 
       "rows and", ncol(fe), "columns" )
  # Close the connection
  odbcCloseAll( )
  # Return the data tables
  return( fe )
}  # End GrablogsDat function

# Remove rows with NA values in specific columns within a dataframe
completeFun <- function(data, desiredCols) {
  completeVec <- complete.cases(data[, desiredCols])
  return(data[completeVec, ])
}

###################################
#### Fisheries with Point data ####
###################################

# Parameters for each fishery
name <- c( "Crab","Euphausiid","Geoduck","Goose_barnacle_1997_99","Goose_barnacle_2000_05",
              "Horseclam","Octopus_dive","Octopus_trap","Opal_squid","Prawn","Scallop_dive","Scallop_trawl","Shrimp_trawl" )
# sf_log_db$ is mapped to the L:/ drive
# sf_bio_db$ is mapped to the K:/ drive
database <- c( "L:/CrabLogs.mdb","L:/EuphausiidLogs.mdb","L:/GeoduckLogs.mdb","L:/GooseBarnacleLogs.mdb",
            "K:/GooseBarnacle_Bio.mdb","L:/HorseClamLogs.mdb","L:/OctopusDiveLogs.mdb","L:/OctopusTrapLogs.mdb","L:/Squid_ZLogs.mdb",
            "L:/PrawnLogs.mdb","L:/ScallopDiveLogs.mdb","L:/ScallopTrawlLogs.mdb","L:/ShrimpTrawlLogs.mdb" ) 
records <- c( "Logbook","Logbook","Logbook","Logbook","logbook_bio","Logbook","Logbook","Logbook",
                    "Logbook","Catch","Logbook","Logbook","Logbook" )
degree.lower <- c( TRUE,TRUE,FALSE,TRUE,TRUE,FALSE,FALSE,TRUE,TRUE,TRUE,FALSE,TRUE,TRUE )
tdate <- c( FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,TRUE,FALSE,FALSE,FALSE ) 
degree.upper <- c( FALSE,FALSE,TRUE,FALSE,FALSE,TRUE,TRUE,FALSE,FALSE,FALSE,TRUE,FALSE,FALSE )
degree.long <- c( FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE )

# Create a dataframe to hold the unique set of parameters for each fishery
fisheries <- data.frame( name, database, records, degree.lower, tdate, degree.upper, degree.long )
fisheries$name <- as.character(fisheries$name)
fisheries$database <- as.character(fisheries$database)
fisheries$records <- as.character(fisheries$records)

# Loop through dataframe, read in fishing events, correct formatting, write shapefile
for (i in 1:nrow(fisheries)){
  # Assign parameters
  fishery <- fisheries[i,1]
  locDB <- fisheries[i,2]
  fishingEvents <- fisheries[i,3]
  cat(fishery, " fishery ...")
  # Read in fishing events
  fe <- GrabFishingDat( db=locDB, logs=fishingEvents )
  #head(fe)
  # Correct for difference in lat/long/year formatting
  if ( fisheries$degree.lower[i] == TRUE ){
    fe$lon <- ( (fe$long_deg) + (fe$long_min/60) )
    fe$lon <- ( fe$lon*-1 )
    fe$lat <- ( (fe$lat_deg) + (fe$lat_min/60) )
  }
  if ( fisheries$tdate[i] == TRUE ){
    fe$year <- format(fe$tdate, "%Y")
  }
  if ( fisheries$degree.upper[i] == TRUE ){
    fe$lon <- fe$Lon
    fe$lat <- fe$Lat
    fe$Lon <- NULL
    fe$Lat <- NULL
  }
  if ( fisheries$degree.long[i] == TRUE ){
    fe$lon <- ( (fe$Long_deg) + (fe$Long_min/60) )
    fe$lon <- ( fe$lon*-1 )
    fe$lat <- ( (fe$Lat_deg) + (fe$Lat_min/60) )
  }
  # Correct fields in the Geoduck & Horseclam fe tables in order to merge them later
  if ( fisheries$name[i] == "Horseclam" ){
    fe$Season <- ""
    fe$GMA <- fe$quota_area
    fe$quota_area <- NULL
  }
  # Remove rows without lat/lon
  fe <- completeFun( fe,c("lon", "lat") )
  cat(" ...")
  # Assign coordinate fields and create Large SpatialPoints DataFrame
  coordinates(fe) <- c( "lon", "lat" )  # set spatial coordinates
  # Define projection
  crs.geo <- CRS( "+proj=longlat +ellps=GRS80 +datum=NAD83 +no_defs" ) # geographical, datum NAD83
  proj4string(fe) <- crs.geo  # define projection system of our data
  # Write shapefile using writeOGR function
  # Field names will be abbreviated for ESRI Shapefile driver
  writeOGR( fe, dsn='.', layer=fishery, driver="ESRI Shapefile", overwrite_layer=TRUE )
  rm(fe)
  cat(" Created shapefile ...\n" )
}

######################################
#### Fisheries with Polyline data ####
######################################

fishery <- "Tanner"
locDB <- "L:/TannerCrabLogs.mdb"
fishingEvents <- "TannerCatch"
fishingLocations <- "BridgeLog"

# Read in table
cat(fishery, " fishery ...")
fe <- GrabFishingDat( db=locDB, logs=fishingEvents )

# For Tanner Crab need to also grab the BridgeLog table for position data
if (fishery == "Tanner") bLog <- GrabFishingDat( db=locDB, logs=fishingLocations )

# Summarise the fe by TripID & SetNum; where NumMale & NumFemale is not zero
fe$catch <- fe$NumMale + fe$NumFemale
fe <- subset(fe, catch !=0,)
fe <- fe %>% 
         group_by(TripID,SetNum) %>%
         summarise(total_catch=sum(catch))

# Recreate lat/long for start and end
bLog$lon_st <- ( (bLog$LongDegDepSt) + (bLog$LongMinDepSt/60 ) )
bLog$lon_st <- ( bLog$lon_st * -1 )
bLog$lat_st <- ( (bLog$LatDegDepSt) + (bLog$LatMinDepSt/60) )

bLog$lon_end <- ( (bLog$LongDegDepEnd) + (bLog$LongMinDepEnd/60 ) )
bLog$lon_end <- ( bLog$lon_end * -1 )
bLog$lat_end <- ( (bLog$LatDegDepEnd) + (bLog$LatMinDepEnd/60) )

# Remove null positions
bLog <- completeFun( bLog,c("lon_st","lat_st","lon_end","lat_end") )

# Merge two df together
fe.log <- merge (fe, bLog, c("TripID","SetNum"))

# Extract start & end coordinates
begin.coord <- data.frame(lon=fe.log$lon_st, lat=fe.log$lat_st)
end.coord <- data.frame(lon=fe.log$lon_end, lat=fe.log$lat_end)

# Build list of coordinate pairs
sl <- vector("list", nrow(fe.log))
for (i in seq_along(sl)) {
  sl[[i]] <- Lines(list(Line(rbind(begin.coord[i, ], end.coord[i,]))), as.character(i))
}

# Build a spatial line object
set.lines <- SpatialLines(sl)

# Build a SpatialLinesDataFrame to attach the attribute data to
Sldf <- SpatialLinesDataFrame( set.lines, data=fe.log)

# Define projection
crs.geo <- CRS( "+proj=longlat +ellps=GRS80 +datum=NAD83 +no_defs" ) # geographical, datum NAD83
proj4string(Sldf) <- crs.geo  # define projection system of our data

# Write shapefile using writeOGR function
# Field names will be abbreviated for ESRI Shapefile driver
writeOGR( Sldf, dsn='.', layer=fishery, driver="ESRI Shapefile", overwrite_layer=TRUE )
cat(" ... Created shapefile ...\n" )


######################################
#### Merge GDK & HCLM shapefiles  ####
######################################
# Incidental catch of Horseclam in the Geoduck fishery is recorded in a Horseclam logbook database
# Need to merge spatial layers to represent the catch locations used for the Geoduck licence

# Read in shapefiles
InPoints1 = readShapePoints("Geoduck.shp")
InPoints2 = readShapePoints("Horseclam.shp")
 
# Combine the two data components by stacking them row-wise.                     
mergeData = rbind(InPoints1@data,InPoints2@data)  

# Combine the spatial components of the two files
mergePoints = rbind(InPoints1@coords,InPoints2@coords, fix.duplicated.IDs=TRUE)  

# Promote the combined list into a SpatialPoints object
mergePointsSP = SpatialPoints(mergePoints)

# Create the SpatialPointsDataFrame                            
newSPDF = SpatialPointsDataFrame(mergePointsSP, data = mergeData, match.ID=FALSE)

# delete GDK & HCLM shapefiles
# file.remove("Geoduck.shp","Geoduck.dbf","Geoduck.prj","Geoduck.shx")
# file.remove("Horseclam.shp","Horseclam.dbf","Horseclam.prj","Horseclam.shx")

# Define projection
crs.geo <- CRS( "+proj=longlat +ellps=GRS80 +datum=NAD83 +no_defs" ) # geographical, datum NAD83
proj4string(newSPDF) <- crs.geo  # define projection system of our data
# Write new Geoduck shapefile
writeOGR( newSPDF, dsn='.', layer="Geoduck_updated", driver="ESRI Shapefile", overwrite_layer=TRUE )

