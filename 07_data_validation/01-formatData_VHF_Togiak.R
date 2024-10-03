# Objective: Import VHF dataset from Togiak & format it similar to GPS data so that it can be used to validate our habitat selection models.

# Author: A. Droghini (adroghini@alaska.edu)

# Define Git directory ----
git_dir <- "C:/ACCS_Work/Github/southwest-alaska-moose/package_Validation/"

#### Load packages ----
source(paste0(git_dir,"init.R"))

#### Load data ----
togiakData <- readxl::read_excel(paste(input_dir,"validation_points",
                            "2015to2021_moose_calving_lxs.xls",sep="/"))

#### Explore data ----
unique(togiakData$Month) # no need to subset date
unique(togiakData$Bull)
unique(togiakData$Cow) # no need to subset by sex
unique(togiakData$Yrlg)
unique(togiakData$Calf)

#### Format data ----
togiakData <- togiakData %>% 
  select("Moose ID","Obs Date",Longitude, Latitude, Calf) %>% 
  rename(Moose_ID = "Moose ID", "AKDT_Date" = "Obs Date",lonX_WGS84=Longitude, latY_WGS84 = Latitude, calfStatus = Calf) %>% 
  mutate(calfStatus = case_when(calfStatus >= 1 ~ 1,
                                TRUE ~ 0))

# Check
unique(togiakData$calfStatus)

#### Check for outliers ----

# Load study area boundary
study_area = readOGR(dsn=geoDB,layer="StudyArea_Boundary")

# Spatialize VHF data
xy_coords <- coordinates(togiakData %>% select(lonX_WGS84,latY_WGS84))
spatial_pts <- SpatialPointsDataFrame(coords = xy_coords, data = togiakData,
                                      proj4string = CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))

spatial_pts <- spTransform(spatial_pts,study_area@proj4string)

# Plot data
plot(study_area,axes=TRUE)
plot(spatial_pts,add=TRUE)

# Remove points outside of study area boundary
# (Doesn't look like there are any)
no_outliers <- spatial_pts[!is.na(over(spatial_pts, as(study_area, "SpatialPolygons"))),]

rm(xy_coords,spatial_pts)

# Convert to CSV
togiakData <- as.data.frame(no_outliers)

# Relabel coordinates to make projection explicit
togiakData <- togiakData %>% 
  rename(latY_AKAlbers = latY_WGS84.1, lonX_AKAlbers = lonX_WGS84.1)

#### Export data----
write_csv(togiakData,file.path(output_dir,"animalData","cleanedVHFdata_Togiak.csv"))

# As shapefile
file_path = file.path(pipeline_dir,"01-formatData_VHF")
writeOGR(no_outliers, dsn = file_path, layer = "vhf_andy",
         driver = "ESRI Shapefile" )

# Clean workspace
rm(list=ls())