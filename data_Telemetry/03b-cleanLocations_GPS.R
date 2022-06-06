# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Clean animal GPS data - Part 2 (Spatial outliers)
# Author: Amanda Droghini
# Last Updated: 2022-06-06
# Usage: Code chunks must be executed sequentially in R Studio or R Studio Server installation.
# Description: Examine GPS data for issues including outliers, duplicates, and skipped fixes. In order to maintain data confidentiality, all animal ID numbers have been replaced by M####. All mention of coordinates have also been scrubbed.
# ---------------------------------------------------------------------------

rm(list = ls())

# Define Git directory ----
git_dir <- "C:/Work/GitHub/southwest-alaska-moose/package_TelemetryFormatting/"

#### Load packages and functions ----
source(paste0(git_dir,"init.R"))
source(paste0(git_dir,"function-plotOutliers.R"))

#### Load data ----
load(paste0(pipeline_dir, "03a_cleanFixRate/","cleanFixRate.Rdata"))

#### Calculate movement metrics----

## Distances
# Units are in meters
# Not sure what a reasonable sustained (2-hour speed) is but... moose can run.
# Covering distances of 10 km in two hours is probably not ridiculous
gpsMove <- move(x=gpsClean$Easting,y=gpsClean$Northing,
                time=gpsClean$datetime,
                data=gpsClean,proj=CRS("+init=epsg:32604"),
                animal=gpsClean$deployment_id, sensor="gps")

gpsClean$distanceMeters <- unlist(lapply(move::distance(gpsMove), c, NA))

summary(gpsClean$distanceMeters) # NAs should equal number of individuals

#### Examine distance outliers----

which(gpsClean$distanceMeters>8000) # 7 entries

# Plot some of these to see if anything ~fishy~ is going on
plotOutliers(gpsClean,35716,35726) # looks fine
plotOutliers(gpsClean,46568,46588) # 
plotOutliers(gpsClean,138008,138108)
plotOutliers(gpsClean,138307,138407) 
plotOutliers(gpsClean,183825,183925) # looks weird. two consecutive fixes had distances >9km: 183825 and 183826
temp <- plotOutliers(gpsClean,183827,183835,output=TRUE)
temp <- plotOutliers(gpsClean,183820,183835,output=TRUE)
# I would lean towards deleting 90600 and interpolating
which(row.names(temp)==183825)
temp <- temp[-c(6,7),]
plotOutliers(temp,1,14) # looks good now.

rm(temp)

#### Examine speed outliers----
# Units are in m/s

gpsClean$speedKmh <- (unlist(lapply(move::speed(gpsMove),c, NA )))*3.6
summary(gpsClean$speedKmh) # Highest speeds are related to the very high distances we examined in the step before.

#### Using the ctmm::outlie function----
# Generate ctmm::outlie plots for each individual
# High-speed segments are in blue, while distant locations are in red
# The plots identify other movement outliers, but I can't really figure out how to isolate problematic data points.

ctmmData <- ctmm:as.telemetry(gpsMove)
ids <- names(ctmmData)

# Grab some coffee while this runs
for (i in 1:length(ids)){
  ctmm::outlie(ctmmData[[i]],plot=TRUE,main=ids[i])
  plotName <- paste("outliers",ids[i],sep="")
  filePath <- paste("pipeline/telemetryData/gpsData/03b_cleanLocations/temp/",plotName,sep="")
  finalName <- paste(filePath,"png",sep=".")
  dev.copy(png,finalName)
  dev.off()
  rm(plotName,filePath,finalName)
}

rm(i,ids,ctmmData)
dev.off()

# Checking out some wonky-looking movements based on the ctmm plots

# M####
subsetOutlier <- subset(gpsClean,deployment_id=="M####")
plotOutliers(subsetOutlier,1,nrow(subsetOutlier)) # can't identify anything

# M####
subsetOutlier <- subset(gpsClean,deployment_id=="M####")
plotOutliers(subsetOutlier,1,nrow(subsetOutlier))
# Coordinates have been redacted -- subsetOutlier %>% filter(longX> (####) & longX < (####) & latY < (####) & latY > (####))
plotOutliers(subsetOutlier,4800,5000) # need to fix Row ID 4894
plotOutliers(subsetOutlier,5460,5500) # fine
plotOutliers(subsetOutlier,5770,5790) # need to fix Row ID 5778
subsetOutlier <- subsetOutlier %>% filter(RowID!=5778 & RowID!=4894)
plotOutliers(subsetOutlier,1,nrow(subsetOutlier)) # fixes the issues

# M####
subsetOutlier <- subset(gpsClean,deployment_id=="M####")
plotOutliers(subsetOutlier,1,nrow(subsetOutlier)) # based on ctmm plot, there seem to be a couple of outliers but on this plot I can only easily identify one
# Coordinates have been redacted -- subsetOutlier %>% filter(longX> (####) & longX < (####) & latY < (####) & latY > (####)) # rowID 2351
plotOutliers(subsetOutlier,2300,2400)
subsetOutlier <- subsetOutlier %>% filter(RowID!=2351)
plotOutliers(subsetOutlier,1,nrow(subsetOutlier)) # fixes the issue

# M####
subsetOutlier <- subset(gpsClean,deployment_id=="# M####")
plotOutliers(subsetOutlier,1,nrow(subsetOutlier))
# Coordinates have been redacted -- subsetOutlier %>% filter(longX> (####) & longX < (####) & latY < (####) & latY > (####)) # row ID 3616
plotOutliers(subsetOutlier,3500,3640)
subsetOutlier <- subsetOutlier %>% filter(RowID!=3616)
plotOutliers(subsetOutlier,1,nrow(subsetOutlier)) # fixes the issue

# M####
subsetOutlier <- subset(gpsClean,deployment_id=="# M####")
plotOutliers(subsetOutlier,1,nrow(subsetOutlier))
# Coordinates have been redacted -- subsetOutlier %>% filter(longX> (####) & longX < (####) & latY < (####) & latY > (####)) # row ID 1856
plotOutliers(subsetOutlier,1800,1880)
subsetOutlier <- subsetOutlier %>% filter(RowID!=1856)
plotOutliers(subsetOutlier,1,nrow(subsetOutlier))

# other plots look OK

rm(subsetOutlier,plotOutliers)

#### Commit changes ----
# Restart from move object since we will have to recalculate speed and distances

gpsClean <- gpsClean %>%
  filter(!(deployment_id == "M####7" & RowID == 5789 |
             deployment_id=="M####" & RowID == 5778 |
             deployment_id=="M####" & RowID == 4894 |
             deployment_id == "M####" & RowID == 2351 |
             deployment_id=="M####" & RowID == 3616 |
             deployment_id=="M####" & RowID == 1856)) %>%
  dplyr::select(-distanceMeters,-speedKmh)
# Deleted 6 rows

#### Save files----
save(gpsClean,file=paste0(pipeline_dir,"03b_cleanLocations/","cleanLocations.Rdata"))
write_csv(gpsClean, file=paste0(output_dir, "animalData/","cleanedGPSdata.csv"))

# Clean workspace
rm(list=ls())