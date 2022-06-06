# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Clean animal GPS data, Part I (Missed fixes)
# Author: Amanda Droghini
# Last Updated: 2022-06-06
# Usage: Code chunks must be executed sequentially in R Studio or R Studio Server installation.
# Description: Examine GPS data for issues including outliers, duplicates, and skipped fixes. In order to maintain data confidentiality, all animal ID numbers have been replaced by M####. All mention of coordinates have also been redacted.
# ---------------------------------------------------------------------------

rm(list = ls())

# Define Git directory ----
git_dir <- "C:/Work/GitHub/southwest-alaska-moose/package_TelemetryFormatting/"

#### Load packages and functions ----
source(paste0(git_dir,"init.R"))
source(paste0(git_dir,"function-subsetIDTimeLags.R"))

load(paste0(pipeline_dir,"02_formatData/","gpsData_formatted.Rdata"))

#### Calculate time lags----
# According to Vectronic manual (https://vectronic-aerospace.com/wp-content/uploads/2016/04/Manual_GPS-Plus-Collar-Manager-V3.11.3.pdf), Lat/Long is in WGS84.
# Convert to move object
# Required for calculating timeLags
# Use Easting/Northing as coordinates

gpsMove <- move(x=gpsData$Easting,y=gpsData$Northing,
                time=gpsData$datetime,
                data=gpsData,proj=CRS("+init=epsg:3338"),
                animal=gpsData$deployment_id, sensor="gps")

# Will throw a warning if there are any records with NA as coordinates

# show(gpsMove)
# show(split(gpsMove))
n.indiv(gpsMove) # no of individuals
n.locs(gpsMove) # no of locations per individuals

# Explore data for outliers----
# See vignette: https://ctmm-initiative.github.io/ctmm/articles/error.html
#

# 1. Check time lags- missed fixed rates or duplicates. Fix rate is 2 hours. In this data set, most problems stem from unidentified redeployments (addressed in previous script) and collar issues at the start/end of deployment
# 2. Check movement outliers including:
#         a) improbable speeds
#         b) improbable distances
#         c) improbable locations

# Plot coordinates
# Takes a while to load
plot(gpsData$Easting, gpsData$Northing,
     xlab="Easting", ylab="Northing")

summary(gpsData)

# Will tackle other, less noticeable location outliers on a case-by-case basis later

#### Check for time lag/fix rate issues----

# Calculate time lags between locations
timeLags <- move::timeLag(gpsMove, units='hours')
ids <- unique(gpsMove@trackId)

# Generate plots and quantitative summary
timelagSummary <- data.frame(row.names = ids)

for (i in 1:length(ids)){
  timeL <- timeLags[[i]]

  timelagSummary$id[i] <- ids[i]
  timelagSummary$min[i] <- min(timeL)
  timelagSummary$mean[i] <- mean(timeL)
  timelagSummary$sd[i] <- sd(timeL)
  timelagSummary$max[i] <- max(timeL)

  hist(timeL,main=ids[i],xlab="Hours")
  plotName <- paste("timeLags",ids[i],sep="")
  filePath <- paste("pipeline/telemetryData/gpsData/03a_cleanFixRate/temp/",plotName,sep="")
  finalName <- paste(filePath,"png",sep=".")
  dev.copy(png,finalName)
  dev.off()

}

rm(plotName,filePath,finalName,i,timeL)

# Collars with time lag issues----

# Minor problems, largely outside of calving season.

summary(timelagSummary)

# investigating... M####
# Mortality on 4 June 2020
# Drop everything after idx 9430
subsetID <- subsetTimeLags("M####",1.95,2.05) 
View(subsetID[9400:9484,])

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)

View(subsetID[1:10,]) # 1. Collar starts on April 5 2018, but fix rates do not become consistent until April 8 (barely any data from 6-7 Apr). Solution: Delete start (n=6).
View(subsetID[970:985,]) # No data on 28 Jun 2018 (outside of calving season)
View(subsetID[12774:12786,])

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)
View(subsetID[965:975,]) # Same issue as M####. No data on 28 June 2018 (outside of calving season)

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)
View(subsetID[1:10,]) # 1. Collar starts on 5 April 2018, but fixes do not become consistent until 6 April (no data from 15:00 5 April to 3:00 6 April). Solution: Delete start (n=5).
View(subsetID[1704:1715,]) #2. No data for 3AM fix on 8/26/2018 (outside of calving season)

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)

View(subsetID[1:15,]) # 1. Collar starts on 5 April 2018, but fixes do not become consistent until 6 April. Solution: Delete start (n=8).
View(subsetID[1315:1345,]) #2. Missing two fixes at 11AM on 24-25 July 2018 (outside of calving season)
View(subsetID[1995:2005,]) # Missing a fix at 7AM 19 September 2018
View(subsetID[3120:3137,]) # Missing a fix at 1AM 2018-12-22
View(subsetID[4650:4660,]) # Missing a fix at 19:00 2019-04-28
View(id[5827:5833,]) # Missing one whole day (5 Aug 2019). Fix goes from 2019-08-04 15:00:29 to 2019-08-06 17:00:19

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)
View(subsetID[1:10,]) # Fix jumps from 2018-04-05 15:00:42 to 2018-04-05 23:00:15. Solution: Delete start (n=5)
View(subsetID[4855:4930,]) # Datasheet said individual died on (redacted). Stays stationary several days before then. Last time to include will be (redacted). This is the first instance where the moose travels to lon ####	lat ####. All points after that jump around this area.

test <- subset(subsetID,RowID>4800&RowID<4824)
plot(test$longX,test$latY,type="b")
rm(test)

# investigating... M####
# this is one of our individuals that died. date of death on datasheet is indicated as 22-05-2018, but may be earlier
# Calculate step lengths distances
subsetID <- subsetTimeLags("M####",1.95,2.05,stepLengths=TRUE) # no missed fixes identified

# No obvious point at which animal stops moving so don't remove anything off the end for now

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)
View(subsetID[1533:1540,]) # Jumps from 2019-08-06 19:00:43 to 2019-08-07 21:00:29

# investigating... M####
# death date on datasheet written as 20-05-2018
subsetID <- subsetTimeLags("M####",1.95,2.05,stepLengths=TRUE)
View(subsetID[1:8,]) # Jumps from 2018-04-05 15:00:39 to 2018-04-06 05:00:16. Solution: Delete start (n=4)

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)
View(subsetID[1108:1112,])
View(subsetID[1495:1500,]) # Random missed fixes

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)
# Missing a couple of non-consecutive fixes- should be able to interpolate.

# investigating... M####
subsetID <- subsetTimeLags("M####1",1.95,2.05)
View(subsetID[1:7,]) # 1. Solution: Delete start (n=5).
# Missing a couple of other non-consecutive fixes- should be able to interpolate.

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)
# Missing a couple of non-consecutive fixes- should be able to interpolate.

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05) # a few missed fixes

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05) # 1 missed fix

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)
View(subsetID[1:7,]) # 1. Solution: Delete start (n=5).

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)
View(subsetID[1:10,]) # 1. Delete start (n=8).

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)
View(subsetID[1:12,]) # 1. Delete start (n=7). Only missing three more scattered throughout data set.

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)
View(subsetID[6985:7010,])
# Mortality not indicated in the database but it looks like this individual died on (redacted).
# Remove everything after Row ID 6991
# Collar was not retrieved.


# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05) # Missing a couple of non-consecutive fixes

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05)
View(subsetID[1:12,]) # 1. Delete start (n=7). Only missing two more.

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05) # Only missing two fixes

# investigating... M####
subsetID <- subsetTimeLags("M####",1.95,2.05) # good to go

# Workspace clean-up
rm(ids,timeLags,subsetID,subsetTimeLags)

gpsClean <- gpsData %>%
  filter(!(deployment_id == "M####" & RowID > 9430 | 
             deployment_id == "M####" & RowID <= 6 | deployment_id == "M####" & RowID <= 5 |
             deployment_id == "M####" & RowID <= 8 | deployment_id == "M####" & RowID <= 5 |
             deployment_id == "M####" & RowID > 4823 | deployment_id == "M####" & RowID <= 4 |
             deployment_id == "M####" & RowID > 519 |
             deployment_id == "M####" & RowID <= 5 | deployment_id == "M####" & RowID <= 5 |
             deployment_id == "M####" & RowID <= 8 | deployment_id == "M####" & RowID <= 7 |
             deployment_id == "M####" & RowID > 6991 |
             deployment_id == "M####" & RowID <= 7))

# Total number of rows deleted:
nrow(gpsData)-nrow(gpsClean) #5976
# 5629 of those records were from M#### (mortality & unretrieved collar)
(nrow(gpsData)-nrow(gpsClean))/nrow(gpsData)*100 # 2.4% of data

#### Check for duplicated timestamps----
getDuplicatedTimestamps(x=as.factor(gpsClean$deployment_id),timestamps=gpsClean$datetime,sensorType="gps") # none

# Export cleaned data
save(gpsClean,
     file=paste0(pipeline_dir,"03a_cleanFixRate/","cleanFixRate.Rdata"))

# Clean workspace
rm(list=ls())