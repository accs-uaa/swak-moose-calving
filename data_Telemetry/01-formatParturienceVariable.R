# Objective: For every cow, create a variable "Boolean Parturience" that tracks the survival of calves during calving season. This variable will be used to develop separate models for a) females with calf-at-heel (birthing sites) and b) females without calves. For now, we treat twins or triplets as single boolean Calf-At-Heel. If one calf of a twin set dies, then the cow remains in Calf-At-Heel (1) status. We may add a variable of # of calves in the future.

# We drop observations of pregnant cows that have not yet given birth. These observations were originally coded as 0s, but we recoded them as 3s in MS Excel to make it easy to drop them here. The reason we drop them is because we do not want to conflate the movement patterns/vegetation selection of females on their way to birthing site to females with calf-at-heel (if coded as 1) or to females with dead/no calf (at or on their way to foraging sites).

# Author: A. Droghini (adroghini@alaska.edu)

rm(list=ls())

# Define Git directory ----
git_dir <- "C:/ACCS_Work/GitHub/southwest-alaska-moose/package_TelemetryFormatting/"

#### Load packages ----
source(paste0(git_dir,"init.R"))

# Load data ----

data_file <- paste(input_dir,"calving_status/calvingStatus_compiled_2018-2020.xlsx", sep="/")
calf2018 <- read_excel(data_file, sheet="2018",range="A1:Z67")
calf2019 <- read_excel(data_file, sheet="2019",range="A1:AB84")
calf2020 <- read_excel(data_file, sheet="2020",range="A1:W84")

load(file=paste(pipeline_dir,"01_createDeployMetadata/deployMetadata.Rdata", sep="/"))

# Format data ----

# Convert date columns to long form
calf2018 <- calf2018 %>%
  pivot_longer(cols="11 May 2018":"4 June 2018",names_to="AKDT_Date",
               values_to="calfStatus")

calf2019 <- calf2019 %>%
  pivot_longer(cols="11 May 2019":"6 June 2019",names_to="AKDT_Date",
               values_to="calfStatus")

calf2020 <- calf2020 %>%
  pivot_longer(cols="10 May 2020":"31 May 2020",names_to="AKDT_Date",
               values_to="calfStatus")

# Combine all years into single data frame
calfData <- plyr::rbind.fill(calf2018,calf2019,calf2020)

# Add collar ID using moose ID as a key
calfData <- left_join(calfData,deploy,by=c("Moose_ID"="animal_id"))

#Format date
# Drop animals that aren't included in our deployment dataset (1 bull moose)
# Drop values coded as -999
# Drop animals with no sensor_type (i.e., observations only, no VHF or GPS collars)
calfData <- calfData %>%
  mutate(AKDT_Date = as.Date(calfData$AKDT_Date,format="%e %B %Y")) %>%
  dplyr::filter(!(is.na(deployment_id) | calfStatus == -999 | sensor_type=="none")) %>% 
  dplyr::select(deployment_id,sensor_type,AKDT_Date,calfStatus)

### QA/QC ----
unique(calfData$calfStatus)
unique(calfData$sensor_type)
length(unique(subset(calfData,sensor_type=="GPS")$deployment_id)) # 24
length(unique(subset(calfData,sensor_type=="VHF")$deployment_id)) # 55

#### Export data ----
# As .csv file for data sharing
write_csv(calfData, paste0(output_dir,"animalData/","calfStatus_2018-2020.csv"))

# As.Rdata file to use in subsequent scripts because I don't want to deal with reclassifying my dates
save(calfData,file=paste0(pipeline_dir,"01-formatParturienceVariable/","parturienceData.Rdata"))

# Clean workspace
rm(list=ls())

# Determine number of twins in sample ----
# To address a reviewer's comments

# Read in data
calf2018 <- read_excel(data_file, sheet="2018",range="A1:AG67")
calf2019 <- read_excel(data_file, sheet="2019",range="A1:AH84")
calf2020 <- read_excel(data_file, sheet="2020",range="A1:Z84")

load(file=paste(pipeline_dir,"01_createDeployMetadata/deployMetadata.Rdata", sep="/"))

# From a later script
load(file=paste(pipeline_dir,"04-formatForCalvingSeason/",
                           "gpsCalvingSeason.Rdata",sep="/"))

# Format data
calf2018 <- calf2018 %>% 
  select(Moose_ID,`Calves born`) %>% 
  rename(Born = `Calves born`) %>% 
  mutate(year = 2018)

calf2019 <- calf2019 %>% 
  filter(`Calves born` != "NA") %>% 
  select(Moose_ID, `Calves born`) %>% 
  rename(Born = `Calves born`) %>% 
  mutate(Born = as.numeric(Born),
         year = 2019)

calf2020 <- calf2020 %>% 
  select(Moose_ID, Born) %>% 
  mutate(year = 2020)

twins <- plyr::rbind.fill(calf2018,calf2019,calf2020)

# Add collar ID using moose ID as a key
deploy <- deploy %>% 
  select(animal_id,deployment_id)

twins <- left_join(twins,deploy,by=c("Moose_ID"="animal_id"))

# Restrict to animals included in our final sample
ids <- unique(calvingSeason$deployment_id)

twins <- subset(twins, deployment_id %in% ids)

# Calculate number of singletons, twins, etc. per year
birth_data <- twins %>% mutate(count = 1 ) %>% group_by(year,Born) %>%
  summarize(no_females = sum(count))

# Calculate age of female at time of birth. Were non-maternal females less experienced? Could age distribution explain group-level patterns of habitat selection?
birthday <- read_csv("C:/ACCS_Work/Projects/Moose_SouthwestAlaska/Manuscript/Revisions/birth_year_by_id.csv")

twins <- left_join(twins,birthday,by=c("deployment_id"="id"))