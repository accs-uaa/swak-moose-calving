# Objective: Import VHF dataset & format it similar to GPS data so that it can be used to validate our habitat selection models.

# Author: A. Droghini (adroghini@alaska.edu)

# Define Git directory ----
git_dir <- "C:/Users/adroghini/Documents/Repositories/southwest-alaska-moose/package_Validation/"

#### Load packages ----
source(paste0(git_dir,"init.R"))

#### Load data ----
flightData <- read_excel(paste(input_dir,"from_access_database","dbo_FlightIndex.xlsx",sep="/"),
                         sheet="dbo_FlightIndex")
vhfData <- read_excel(paste(input_dir,"validation_points",
                             "dbo_MooseRadioTelemetry.xlsx",sep="/"),
                      sheet="dbo_MooseRadioTelemetry")

load(file.path(pipeline_dir,"01_createDeployMetadata","deployMetadata.Rdata"))
load(file=file.path(pipeline_dir,"01-formatParturienceVariable","parturienceData.Rdata"))

# Format data ----

# Join vhfData with deploy data to get collar ID (where applicable)
# Add negative sign to longitude entries that do not have any.
# Drop entries that do not have coordinates
# Drop entries that have a waypoint number but no coordinates
# Only include entries for which sensor_type = VHF
# Exclude sensor_type = "GPS" (sightings of GPS-collared moose). Want validation dataset to be independent
# Exclude sensor_type = "none". Not enough observations for these individuals and no daily calf status since they couldn't be consistently relocated.
vhfData <- left_join(vhfData,deploy,by=c("Moose_ID"="animal_id")) %>%
  mutate(lonX = case_when (Lon_DD < 0 ~ Lon_DD,
                            Lon_DD > 0 ~ Lon_DD*-1)) %>%
  filter(!(is.na(Lat_DD) | is.na(lonX))) %>%
  filter(sensor_type=="VHF") %>% 
  dplyr::select(Moose_ID,deployment_id,Lat_DD,lonX,FlightIndex_ID)

# Add observation dates ----
# Join vhfData with flightData to obtain date of observation
# Rename lat lon columns to match with GPS data formatting
flightData <- dplyr::select(.data=flightData,FlightIndex_ID,Flight_Date)

vhfData <- left_join(vhfData,flightData,by="FlightIndex_ID") %>%
  dplyr::select(-FlightIndex_ID) %>%
  rename(AKDT_Date = Flight_Date,latY = Lat_DD) %>%
  mutate(AKDT_Date = as.Date(AKDT_Date))

# Add calving status
# Exclude all entries that do not have an associated calving status
vhfData <- left_join(vhfData,calfData,by = c("deployment_id", "AKDT_Date")) %>% 
  filter(!is.na(calfStatus))

rm(deploy,flightData,calfData)

# QA/QC ----

# Explore sample size
table(vhfData$deployment_id,vhfData$sensor_type)

# Remove spatial outliers

# Load study area boundary
study_area = readOGR(dsn=geoDB,layer="StudyArea_Boundary")

# Spatialize VHF data
xy_coords <- coordinates(vhfData %>% select(lonX,latY))
spatial_pts <- SpatialPointsDataFrame(coords = xy_coords, data = vhfData,
                                      proj4string = CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))


spatial_pts <- spTransform(spatial_pts,study_area@proj4string)

# Plot data
plot(study_area,axes=TRUE)
plot(spatial_pts,add=TRUE)

# Remove points outside of study area boundary
no_outliers <- spatial_pts[!is.na(over(spatial_pts, as(study_area, "SpatialPolygons"))),]

# Check
plot(study_area, axes=TRUE)
plot(no_outliers,add=TRUE)

rm(xy_coords,spatial_pts)

# Convert to CSV
vhfData <- as.data.frame(no_outliers)

# Relabel coordinates to make projection explicit
vhfData <- vhfData %>% 
  rename(latY_WGS84 = latY, lonX_WGS84 = lonX, latY_AKAlbers = latY.1, lonX_AKAlbers = lonX.1) %>% 
  select(Moose_ID, deployment_id,sensor_type,AKDT_Date,lonX_WGS84,latY_WGS84,everything())

#### Export data----
write_csv(vhfData,file.path(output_dir,"animalData","cleanedVHFdata.csv"))

# As shapefile
file_path = file.path(pipeline_dir,"01-formatData_VHF")
writeOGR(no_outliers, dsn = file_path, layer = "vhf_kassie",
         driver = "ESRI Shapefile" )

# Clean workspace
rm(list=ls())