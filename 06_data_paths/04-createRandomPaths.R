# Objective: Generate 1200 random paths for every moose-year. Each random path has the same number of points as the observed path on which it is based. Step lengths and turning angles are randomly sampled from theoretical distributions, whose parameters were obtained by fitting data from our study population.
# From these 1200 paths, we will select 100 random subsets of 10 paths that do not cross non-habitat e.g. lakes.

# Author: A. Droghini (adroghini@alaska.edu)

rm(list = ls())

# Define Git directory ----
git_dir <- "C:/ACCS_Work/GitHub/southwest-alaska-moose/package_Paths/"

#### Load packages and functions ----
source(paste0(git_dir,"init.R"))
source(paste0(git_dir,"function-createRandomPaths.R"))

#### Load data ----
load(file=paste(pipeline_dir,"04-formatForCalvingSeason","gpsCalvingSeason.Rdata",sep="/"))
load(file=paste(pipeline_dir,"01-generateDistributions",
                 "theoreticalDistributions.Rdata",
                sep="/"))

# Random starting points
randomPoints <- readOGR(dsn=geoDB,layer="randomStartPts")
randomPoints <- randomPoints@data
# Create unique ID for random points
randomPoints$id <- seq(from=1, to=nrow(randomPoints), by=1)

#### Create summary data ----

numPaths = 1200

# Lists all moose-year IDs
# Calculates number of points on every observed path
# Defines number of paths that are to be generated for every moose-year
# Rename variables to correspond with internal function naming
observedPaths <- calvingSeason %>%
  filter(RowID==1) %>% 
  dplyr::select(mooseYear_id,calfStatus) %>% 
  mutate(length = (plyr::count(calvingSeason, "mooseYear_id"))$freq,
         numberOfPaths = numPaths) %>% 
  dplyr::rename(idYearStatus = mooseYear_id, 
         status = calfStatus)

#### Run function ----
print('Generating random paths...')

start = proc.time()

pathsList <- createRandomPaths(randomPoints = randomPoints, 
                               pathInfo = observedPaths,
                               dist = dist)

end = proc.time() - start
print(end[3])

#### Convert list to dataframe ----
pathsDf <- lapply(pathsList, function(x) do.call(rbind, x))
pathsDf <- data.table::rbindlist(pathsDf,use.names=FALSE,idcol=TRUE)
pathsDf$rowID <- as.integer(row.names(pathsDf))

# The result is wide dataframe where each row represents the nth point on a path. E.g., If path id #1 has a length of 192 points, there will be 192 rows for that path id. XY coordinate pairs are listed as columns. All the x's are listed first, followed by all of the y's. E.g. if 2 random paths are generated, columns "V1" and "V2" represent the 1st and 2nd iterations of random x coordinates. Columns "V3" and "V4" represent the 1st and 2nd iterations of random y coordinates. Columns "V1" and "V3" form a xy pair.

# Specify start and end of coordinate column names to pivot_longer on. Names depend on the number of paths that are generated.
colx1 <- "V1"
colx2 <- paste0("V",numPaths)
coly1 <- paste0("V",(numPaths+1))
coly2 <- paste0("V",(numPaths*2))

# Pivot dataframe into long format and generate sequential number for every x,y, coordinate in a path, treating X and Y coordinate columns separately.
pathsX <- pathsDf %>% 
  tidyr::pivot_longer(cols=all_of(colx1):all_of(colx2),names_to="pathID",names_prefix="V",values_to=c("x")) %>% 
  dplyr::select(-c(all_of(coly1):all_of(coly2))) %>% 
  mutate(pathID = as.numeric(pathID)) %>% 
  arrange(.id,pathID,rowID)

pathsY <- pathsDf %>% 
  pivot_longer(cols=all_of(coly1):all_of(coly2),
               names_to="pathID",names_prefix="V",values_to=c("y")) %>% 
  dplyr::select(-c((all_of(colx1):all_of(colx2)))) %>% 
  mutate(pathID = (as.numeric(pathID)-numPaths)) %>% 
  arrange(.id,pathID,rowID)

randomPaths <- left_join(pathsX,pathsY,by=c(".id","pathID","rowID")) %>%
  mutate(fullPath_id = paste(.id,pathID,sep="-")) %>% 
  group_by(fullPath_id) %>% 
  arrange(.id,pathID,rowID) %>% 
  dplyr::mutate(pointID = row_number(rowID), 
                fullPoint_id = paste(.id,pathID,pointID,sep="-")) %>% 
  dplyr::rename(mooseYear_id = .id) %>% 
  dplyr::select(mooseYear_id,pathID,pointID,x,y,fullPath_id,fullPoint_id)

# Clean workspace
rm(pathsDf,pathsList,pathsX,pathsY, colx1, colx2, coly1, coly2)

#### Combine random & observed paths ----

# Create logistic response
randomPaths$response <- "0"
calvingSeason$response <- "1"

# Add calfStatus variable to randomPaths
# This variable will be used to split paths into two groups (cows with and without calves) and run two separate models
statusObserved <- calvingSeason %>% 
  dplyr::select(mooseYear_id,RowID,calfStatus,deployment_id)

randomPaths <- left_join(randomPaths,
                    statusObserved,by=c("mooseYear_id"="mooseYear_id",
                                        "pointID"="RowID"))
rm(statusObserved)

# Remove superfluous rows from observed paths
# Rename columns to match random paths
names(calvingSeason)
calvingSeason <- calvingSeason %>% 
  dplyr::select(mooseYear_id,RowID,Easting,Northing,calfStatus,
                response,deployment_id) %>% 
  dplyr::rename(x = Easting, y = Northing, pointID = RowID) %>% 
  mutate(pathID = "observed",
         fullPath_id = paste(mooseYear_id,pathID,sep="-"),
         fullPoint_id = paste(mooseYear_id,pathID,pointID,
                              sep="-"))

# Join datasets
allPaths <- rbind.fill(calvingSeason,randomPaths)

# Check that no random point is the same
tmp <- allPaths %>% 
  mutate(xy = paste0(x,y)) %>%
  filter(xy %in% unique(.[["xy"]][duplicated(.[["xy"]])])) %>% 
  filter(response==0)

#### Export data ----
# To verify results in GIS
# Projection is EPSG = 3338, NAD 83 Alaska Albers
write_csv(allPaths,file=paste(pipeline_dir, "04-createRandomPaths",
                               "allPaths.csv",
                              sep="/"))

# Clear workspace
rm(list=ls())