# File: CA change analysis script (2009-2020).R
# Purpose: Change analysis of Florida Confined Aquifer data generated by 
#  the Status monitoring Program. Created by Jay Silvanima using code developed 
#  by Tony Olsen, myself, Chris Sedlacek, Stephanie Sunderman-Barnes, 
#  and Liz Miller on 05-21-2021.
# Code developed using R version 3.6.2 (2019-12-12), spsurvey version
#   4.1.0, and FDEPgetdata version 1.6.

##Set directory. This is where the outputs will be saved. 
#   Alter to desired location. Use getwd() to determine the directory for
#     your r project.

setwd('C:/R/Change Analysis/GW 2009-2020/Confined') 

# First pull data via use of package 'FDEPgetdata'. 

# Load libraries for the data analyses

library(FDEPgetdata)
library(spsurvey)
library(sf)
library(ggplot2)
library(lubridate)

# Run function of FDEPgetdata package which pulls exclusion data.
#
# Insert varible names between parentheses in function call below. The
#  function will pull the site information for the water resource by year. 
# Entering "'2020'","'CA09','CA10','CA11','CA18','CA19','CA20'" for variables will 
#  create 3 data frames: 1) A data frame (Exclusions) containing all well evaluations 
#  for the periods 2009, 2010, 2011, 2018, 2019, 2020. 2) A data frame (well_removals) containing all 
#  wells evaluated for these time periods which are no longer included in the 
#  2020 target population. 3) A data frame (SiteEvaluations) containing the wells 
#  which were evaluated and present in the well list frame for the most recent 
#  year evaluated.
#
# Be sure to enclose both variables in double quotes.#
#
# Water resource acronyms are CA = Confined Aquifers, UA = Unconfined Aquifers.
#
# The three data frames are exported to the working directory as .csv files.


FDEPgetdata::getdata_aq_exclusions_multi_yr("'2020'","'CA09','CA10','CA11','CA18','CA19','CA20'")

# view well_removals

View(well_removals)

# We need to remove the 212 wells which are not found in the 2020 list frame
#  from the analyses. This was also done by the function and the resultant data
#  frame is named SiteEvaluations.
#
# Take a look at SiteEvaluations next.

View(SiteEvaluations)

# Create new data frame by cloning SiteEvaluations and name it CA.SITES1 because
#  it contains the wells from the first time period to be used in the analysis.

CA.SITES<-SiteEvaluations

# Print out data frame column names in console

names(CA.SITES)

### These are the wells which were evaluated for the two time periods which are present
#    in the 2020 listframe.  1330 wells.  
#
# Note there are 212 wells which do not match the target population from 2020.
# We will be using this data frame (well_removals) later on in this analysis process.
# Create new dataframe to for these well removals

well_removals_2020 <- well_removals

# Now need to create the data frame for the first time period.

FDEPgetdata::getdata_aq_exclusions_multi_yr("'2011'","'CA09','CA10','CA11'")

View(SiteEvaluations)

# Create new data frame by cloning SiteEvaluations and name it CA.SITES1 because
#  it contains the wells from the first time period to be used in the analysis.

CA.SITES1<-SiteEvaluations

# Print out data frame column names in console

names(CA.SITES1)

# Convert to Decimal degrees and do map projection

deg <- floor(CA.SITES1$RANDOM_LATITUDE/10000)
min <- floor((CA.SITES1$RANDOM_LATITUDE - deg*10000)/100)
sec <- CA.SITES1$RANDOM_LATITUDE - deg*10000 - min*100
CA.SITES1$latdd <- deg + min/60 + sec/3600
deg <- floor(CA.SITES1$RANDOM_LONGITUDE/10000)
min <- floor((CA.SITES1$RANDOM_LONGITUDE - deg*10000)/100)
sec <- CA.SITES1$RANDOM_LONGITUDE - deg*10000 - min*100
CA.SITES1$londd <- deg + min/60 + sec/3600

# Change londd to negative for correct use in sf.
CA.SITES1$londd <- -CA.SITES1$londd

# Create sf object and transform to Albers projection for analysis
#  This codes utilizes Coordinate Reference System (CRS/EPSG) Codes.
#  The first crs code (4269) below is for NAD 83 coordinate system the 
#  second crs code (3087) is for Florida albers projection. 
#  More information on these codes is found here: 
#  https://www.nceas.ucsb.edu/sites/default/files/2020-04/OverviewCoordinateReferenceSystems.pdf.

dsgn_aq <- st_as_sf(CA.SITES1, coords = c("londd", "latdd"), remove = FALSE,
                    crs = 4269)
dsgn_sf <- st_transform(dsgn_aq, crs = 3087)

# keep xy coords as variables
tmp <- st_coordinates(dsgn_sf)
dsgn_sf$xcoord <- tmp[, "X"]
dsgn_sf$ycoord <- tmp[, "Y"]

# plot sites using sf
plot(st_geometry(dsgn_sf))

# Examine plot for oddities.

# Site Evaluation
#  The variables CAN_BE_SAMPLED, EXCLUSION_CATEGORY and EXCLUSION_CRITERIA 
#   provide information on the site evaluation results for each site. 
#  Review the information and create target/nontarget (TNT) variable.

addmargins(table(dsgn_sf$EXCLUSION_CATEGORY, dsgn_sf$CAN_BE_SAMPLED, useNA = 'ifany'))
addmargins(table(dsgn_sf$EXCLUSION_CRITERIA, useNA = 'ifany'))


# create sampled and target (T) / nontarget (NT) variables

dsgn_sf$EXCLUSION_CATEGORY <- as.character(dsgn_sf$EXCLUSION_CATEGORY)
dsgn_sf$EXCLUSION_CATEGORY[dsgn_sf$CAN_BE_SAMPLED == 'Y'] <- 'SAMPLED'
dsgn_sf$EXCLUSION_CATEGORY <- as.factor(dsgn_sf$EXCLUSION_CATEGORY)
levels(dsgn_sf$EXCLUSION_CATEGORY)
dsgn_sf$TNT <- dsgn_sf$EXCLUSION_CATEGORY
levels(dsgn_sf$TNT) <- list(T=c('SAMPLED', 'NO PERMISSION FROM OWNER', 'UNABLE TO ACCESS','OTHERWISE UNSAMPLEABLE','DRY'),
                            NT=c('WRONG RESOURCE/NOT PART OF TARGET POPULATION') )


# Look at distribution of evaluated sites by reporting unit and time period

addmargins(table(dsgn_sf$REPORTING_UNIT, dsgn_sf$REPORTING_UNIT, useNA = 'ifany'))

#        ZONE 1 ZONE 2 ZONE 3 ZONE 4 ZONE 5 ZONE 6 Sum
# ZONE 1    122      0      0      0      0      0 122
# ZONE 2      0    123      0      0      0      0 123
# ZONE 3      0      0    106      0      0      0 106
# ZONE 4      0      0      0     95      0      0  95
# ZONE 5      0      0      0      0     98      0  98
# ZONE 6      0      0      0      0      0     46  46
# Sum       122    123    106     95     98     46 590


# Note need frame size here found in design doc for confined aquifer site selections
# Z:\Chris site selection process\Cycle 5 2011 selections\2011 well selections\FL GW Wells 2011.doc
#  From design document framesize # confined wells = 15,339 for entire data frame.


framesize <- c("ZONE 1"=7006,"ZONE 2"=361,"ZONE 3"=1006,"ZONE 4"=896,
               "ZONE 5"=245,"ZONE 6"=12)


# use all evaluated sites to adjust weights
nr <- nrow(dsgn_sf)
dsgn_sf$wgt <- adjwgt(rep(TRUE,nr), dsgn_sf$WELL_WEIGHT, 
                      dsgn_sf$REPORTING_UNIT, framesize=framesize)

# check sum of weights for each reporting unit/basin
addmargins(tapply(dsgn_sf$wgt, dsgn_sf$REPORTING_UNIT, sum))

# ZONE 1 ZONE 2 ZONE 3 ZONE 4 ZONE 5 ZONE 6    Sum 
#   7006    361   1006    896    245     12   9526 

##### This just created the simple feature dsgn files for time period 1 2009-2011
## Now clone the data frame and name them dsgn_aq1, dsgn_sf1.

dsgn_aq1 <- dsgn_aq
dsgn_sf1 <- dsgn_sf

### Now need to create the data frame for the second time period.

FDEPgetdata::getdata_aq_exclusions_multi_yr("'2020'","'CA18','CA19','CA20'")

# view well_removals

View(well_removals)

# We need to remove the 55 wells which are not found in the 2020 list frame
#  from the analyses. This was also done by the function and the resultant data
#  frame is named SiteEvaluations.
#
# Take a look at SiteEvaluations next.

View(SiteEvaluations)

# Create new data frame by cloning SiteEvaluations and name it CA.SITES2 because it
#  contains the wells from second time period.

CA.SITES2<-SiteEvaluations

# Print out data frame column names in console

names(CA.SITES2)

# Convert to Decimal degrees and do map projection

deg <- floor(CA.SITES2$RANDOM_LATITUDE/10000)
min <- floor((CA.SITES2$RANDOM_LATITUDE - deg*10000)/100)
sec <- CA.SITES2$RANDOM_LATITUDE - deg*10000 - min*100
CA.SITES2$latdd <- deg + min/60 + sec/3600
deg <- floor(CA.SITES2$RANDOM_LONGITUDE/10000)
min <- floor((CA.SITES2$RANDOM_LONGITUDE - deg*10000)/100)
sec <- CA.SITES2$RANDOM_LONGITUDE - deg*10000 - min*100
CA.SITES2$londd <- deg + min/60 + sec/3600

# Change londd to negative for correct use in sf.
CA.SITES2$londd <- -CA.SITES2$londd

# Create sf object and transform to Albers projection for analysis
#  This codes utilizes Coordinate Reference System (CRS/EPSG) Codes.
#  The first crs code (4269) below is for NAD 83 coordinate system the 
#  second crs code (3087) is for Florida albers projection. 
#  More information on these codes is found here: 
#  https://www.nceas.ucsb.edu/sites/default/files/2020-04/OverviewCoordinateReferenceSystems.pdf.

dsgn_aq <- st_as_sf(CA.SITES2, coords = c("londd", "latdd"), remove = FALSE,
                    crs = 4269)
dsgn_sf <- st_transform(dsgn_aq, crs = 3087)

# keep xy coords as variables
tmp <- st_coordinates(dsgn_sf)
dsgn_sf$xcoord <- tmp[, "X"]
dsgn_sf$ycoord <- tmp[, "Y"]

# plot sites using sf
plot(st_geometry(dsgn_sf))

# Examine plot for oddities.

# Site Evaluation
#  The variables CAN_BE_SAMPLED, EXCLUSION_CATEGORY and EXCLUSION_CRITERIA 
#   provide information on the site evaluation results for each site. 
#  Review the information and create target/nontarget (TNT) variable.

addmargins(table(dsgn_sf$EXCLUSION_CATEGORY, dsgn_sf$CAN_BE_SAMPLED, useNA = 'ifany'))
addmargins(table(dsgn_sf$EXCLUSION_CRITERIA, useNA = 'ifany'))


# create sampled and target (T) / nontarget (NT) variables

dsgn_sf$EXCLUSION_CATEGORY <- as.character(dsgn_sf$EXCLUSION_CATEGORY)
dsgn_sf$EXCLUSION_CATEGORY[dsgn_sf$CAN_BE_SAMPLED == 'Y'] <- 'SAMPLED'
dsgn_sf$EXCLUSION_CATEGORY <- as.factor(dsgn_sf$EXCLUSION_CATEGORY)
levels(dsgn_sf$EXCLUSION_CATEGORY)
dsgn_sf$TNT <- dsgn_sf$EXCLUSION_CATEGORY
levels(dsgn_sf$TNT) <- list(T=c('SAMPLED', 'NO PERMISSION FROM OWNER', 'UNABLE TO ACCESS','OTHERWISE UNSAMPLEABLE','DRY'),
                            NT=c('WRONG RESOURCE/NOT PART OF TARGET POPULATION') )


# Look at distribution of evaluated sites by reporting unit and time period

addmargins(table(dsgn_sf$REPORTING_UNIT, dsgn_sf$REPORTING_UNIT, useNA = 'ifany'))

#         ZONE 1 ZONE 2 ZONE 3 ZONE 4 ZONE 5 ZONE 6 Sum
#  ZONE 1    242      0      0      0      0      0 242
#  ZONE 2      0    177      0      0      0      0 177
#  ZONE 3      0      0    114      0      0      0 114
#  ZONE 4      0      0      0    118      0      0 118
#  ZONE 5      0      0      0      0    119      0 119
#  ZONE 6      0      0      0      0      0     67  67
#  Sum       242    177    114    118    119     67 837


# Note need frame size here found in design doc for confined aquifer site selections
#  Z:\Chris site selection process\2020 site selections\2020 wells\FL GW Wells 2020.doc
#  From design document framesize # confined wells = 15,339 for entire data frame.


framesize <- c("ZONE 1"=10349,"ZONE 2"=2706,"ZONE 3"=1163,"ZONE 4"=889,
               "ZONE 5"=207,"ZONE 6"=25)

# use all evaluated sites to adjust weights
nr <- nrow(dsgn_sf)
dsgn_sf$wgt <- adjwgt(rep(TRUE,nr), dsgn_sf$WELL_WEIGHT, 
                      dsgn_sf$REPORTING_UNIT, framesize=framesize)

# check sum of weights for each reporting unit/basin
addmargins(tapply(dsgn_sf$wgt, dsgn_sf$REPORTING_UNIT, sum))

# ZONE 1 ZONE 2 ZONE 3 ZONE 4 ZONE 5 ZONE 6    Sum 
#  10349   2706   1163    889    207     25  15339 

##### This just created the simple feature dsgn file for time period 1 2009-2011
## Now clone the data frame and name it dsgn_sf2.

dsgn_aq2 <- dsgn_aq
dsgn_sf2 <- dsgn_sf

######## Now need to merge the two dsgn data frames for the analysis.

dsgn_aq <- rbind(dsgn_aq1, dsgn_aq2)
dsgn_sf <- rbind(dsgn_sf1, dsgn_sf2)

# Next have to codify time periods 1 (2009-2011) and 2 (2018-2020)
# first create column to hold time periods

dsgn_sf$time_period <- dsgn_sf$REPORTING_CYCLE

# Next update column with correct information

dsgn_sf$time_period <- ifelse(dsgn_sf$time_period == 3, 1, 
                                      ifelse(dsgn_sf$time_period == 4, 1,
                                             ifelse (dsgn_sf$time_period == 5, 1,dsgn_sf$time_period)))

dsgn_sf$time_period <- ifelse(dsgn_sf$time_period == 12, 2, 
                                      ifelse(dsgn_sf$time_period == 13, 2,
                                             ifelse (dsgn_sf$time_period == 14, 2,dsgn_sf$time_period)))

# Create column for the year

dsgn_sf$yr<- year(dsgn_sf$SAMPLED_DATE)

# plot sites using sf
plot(st_geometry(dsgn_sf))


# Look at weight sums the two time periods.

tmp <- tapply(dsgn_sf$wgt, list(dsgn_sf$time_period, dsgn_sf$REPORTING_UNIT), sum)
tmp[is.na(tmp)] <- 0
round(addmargins(tmp), 1)

#     ZONE 1 ZONE 2 ZONE 3 ZONE 4 ZONE 5 ZONE 6    Sum
# 1   3397.3  173.1  526.7  555.3  149.6    8.0 4809.9
# 2   2534.1  834.4  547.2  429.6  103.9   21.2 4470.4
# Sum 5931.4 1007.4 1073.8  984.9  253.5   29.2 9280.4

# Zone totals for each time period are close. 


# Create a data frame of consisting of only the following columns found in dsgn_sf

names(dsgn_sf)

# Need to remove geometry column because function sqldf does not handle geometry
#  column type.

dsgn_sf <- st_set_geometry(dsgn_sf, NULL)

# Now need to remove all wells which are no longer in the target population 
#  from dsgn_sf data frame.

dsgn_sf <- sqldf('select * from dsgn_sf
          where PK_RANDOM_SAMPLE_LOCATION not in (select PK_RANDOM_SAMPLE_LOCATION
            from well_removals_2020)
          order by PK_RANDOM_SAMPLE_LOCATION')


#########################################################################################
#########################################################################################
# Water Quality Data

# Run function of FDEPgetdata package to pull result data. 
#
# Insert varible name between parentheses in function call below. The
#  function will pull the water resource for the water resource by year. 
#  For example confined aquifer projects during year 2020 the enty would 
#  be "'CA20'". Entering "'CA18','CA19','CA20'" for variable will produce a 
#  dataframe for FDEP Status confined aquifers sampled 2018 - 2020.
#  Be sure to enclose in double and single quotes.
#
# Water resource acronyms are CA = Confined Aquifers, UA = Unconfined Aquifers
#
# The data frame is exported to the working directory as a .csv file.

FDEPgetdata::getdata_results("'CA09','CA10','CA11','CA18','CA19','CA20'")

# Function getdata_results creates the data frame 'Results'.

# Examine the Results data frame.  If more than two columns are present for 
#  each parameter, the data set includes samples with multiple results for at 
#  least one parameter.  Need to locate the affected samples and investigate 
#  further.  Type c(" in the R Studio search bar to search the results data 
#  frame for the affected samples.

# Create new data frame by cloning Results and name it CA_RSLTS.

CA_RSLTS<-Results

# Determine sample types in file.
addmargins(table(CA_RSLTS$SAMPLE_TYPE, CA_RSLTS$MATRIX, useNA = 'ifany'))

#                   WATER Sum
#  BLANK              65  65
#  EQUIPMENT BLANK    29  29
#  FIELD BLANK        43  43
#  PRIMARY           694 694
#  Sum               831 831

# Print out data frame column names in console. You may need them later.

names(CA_RSLTS)

# Need to remove a duplicate row in the data frame Z2-CA-3040 had two rows.
#  The well sampled on 3/3/2009 18:23 was the incorrect well.

CA_RSLTS <- sqldf('select * from CA_RSLTS
          where FK_STATION not in (1460)')

# Now remove all non primary water samples

keep <- CA_RSLTS$SAMPLE_TYPE == 'PRIMARY' & CA_RSLTS$MATRIX == 'WATER'

# merge with design data frame

CA_WQ <- merge(as.data.frame(dsgn_sf)[, c("PK_RANDOM_SAMPLE_LOCATION",
              "REPORTING_UNIT", "REPORTING_CYCLE", "EXCLUSION_CATEGORY","TNT", 
              "wgt", "londd", "latdd", "xcoord", "ycoord", "time_period", "yr")], 
              CA_RSLTS[keep,], 
                   by.x = 'PK_RANDOM_SAMPLE_LOCATION', 
                   by.y = 'FK_RANDOM_SAMPLE_LOCATION')

# check that have only PRIMARY for Water MATRIX data
addmargins(table(CA_WQ$SAMPLE_TYPE, CA_WQ$MATRIX, useNA = 'ifany'))

# Output ....

#                 WATER Sum
# BLANK               0   0
# EQUIPMENT BLANK     0   0
# FIELD BLANK         0   0
# PRIMARY           651 651
# Sum               651 651

# Determine number of wells sampled in each time period

addmargins(table(CA_WQ$time_period, CA_WQ$MATRIX, useNA = 'ifany'))

#     WATER Sum
# 1     300 300
# 2     351 351
# Sum   651 651

# Look at weight sums the two time periods.

tmp <- tapply(CA_WQ$wgt, list(CA_WQ$time_period, CA_WQ$REPORTING_UNIT), sum)
tmp[is.na(tmp)] <- 0
round(addmargins(tmp), 1)

#     ZONE 1 ZONE 2 ZONE 3 ZONE 4 ZONE 5 ZONE 6    Sum
# 1   3397.3  162.0  491.1  532.6  135.5    4.9 4723.3
# 2   2534.1  834.4  547.2  429.6  103.9   21.2 4470.4
# Sum 5931.4  996.4 1038.3  962.2  239.4   26.1 9193.7

# The weights do not differ by much, therefore no further weight adjustments necessary.

# export CA_WQ data frame to .csv file, clear varibles, and then recalc nr
#  for the design.

write.csv(CA_WQ, file='CA_WQ.csv')

rm(deg,keep,min,sec)

nr<-nrow(CA_WQ)


################################################################## 
##################################################################

# Now to create the dataframe for the sites to be used in the change analysis

mysites <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                      Survey1=ifelse(CA_WQ$time_period=="1",TRUE,FALSE),
                      Survey2=ifelse(CA_WQ$time_period=="2", TRUE,FALSE))


##################################################################
### Define subpopulations (reporting units) and create design for
### Florida's TMDL basins
##################################################################

mysubpop <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION,
                       Combined=rep("Basins Combined", nr), 
                       Basin=CA_WQ$REPORTING_UNIT )

mydsgn <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                     wgt=CA_WQ$wgt,
                     xcoord=CA_WQ$xcoord,
                     ycoord=CA_WQ$ycoord,
                     stratum=CA_WQ$REPORTING_UNIT)

################################################################
###Create Total Nitrogen column and populate it
################################################################

CA_WQ$TN<-(CA_WQ$Kjeldahl_Nitrogen_Total_as_N+CA_WQ$NitrateNitrite_Total_as_N)


########################################################################
### Create categorical and continuous distribution of specific indicator
### to run change analysis on
########################################################################

Arsenic <- cut(CA_WQ$Arsenic_Total, breaks=c(0,10,100000), include.lowest=TRUE)
CA_WQ$Arsenic <- Arsenic
CA_WQ$Arsenic <- as.factor(CA_WQ$Arsenic)

mydata.cat <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                           X1002category=CA_WQ$Arsenic
)

mydata.cont <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                         arsenic=CA_WQ$Arsenic_Total
)

# now the total arsenic change.analysis

CategoryArsenic <- change.analysis(sites=mysites, subpop=mysubpop, design=mydsgn,
                                   data.cat=mydata.cat,data.cont=mydata.cont, test=c("mean","median"))
                                                                                                        
# Received the following error and had to remove the row of for Z2-CA-3040 with
#  the first date (3/3/2009 18:23).  I assumed the first sampling event sampled 
#  an incorrect well and this caused a resampling event for the correct well.

#Error in dframe.check(sites_1, design_1, subpop_1, data.cat_1, data.cont_1,  : 
#           The following site ID values in the sites data frame occur more than 
#           once: Z2-CA-3040


# write out results
CategoryArsenic

write.csv(CategoryArsenic$catsum,file='Arseniccatsum.csv')
write.csv(CategoryArsenic$contsum_mean,file='Arseniccontsummean.csv')
write.csv(CategoryArsenic$contsum_median,file='Arseniccontsummedian.csv')


# next analyte Total coliform
### Script to do categories for pie charts31501TotalColiform
Coliform_Total <- cut(CA_WQ$Coliform_Total_MF, breaks=c(0,4,10000000), include.lowest=TRUE)
CA_WQ$Coliform_Total <- Coliform_Total
CA_WQ$Coliform_Total <- as.factor(CA_WQ$Coliform_Total)


mydata.cat <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                         poop=CA_WQ$Coliform_Total
)
mydata.cont <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                          poop=CA_WQ$Coliform_Total_MF
)

# now the total coliform change.analysis

CategoryTotcoliform <- change.analysis(sites=mysites, subpop=mysubpop, design=mydsgn,
                                   data.cat=mydata.cat,data.cont=mydata.cont,test=c("mean","median"))


# write out results
CategoryTotcoliform

write.csv(CategoryTotcoliform$catsum,file='TotalColiformcatsum.csv')
write.csv(CategoryTotcoliform$contsum_mean,file='TotalColiformcontsummean.csv')
write.csv(CategoryTotcoliform$contsum_median,file='TotalColiformcontsummedian.csv')

# Specific conductance field values

SpCond <- cut(CA_WQ$Specific_Conductance_Field, breaks=c(0,1000,10000), include.lowest=TRUE)
CA_WQ$SpCond <- SpCond
CA_WQ$SpCond <- as.factor(CA_WQ$SpCond)


mydata.cat <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                         speccond=CA_WQ$SpCond
)
mydata.cont <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                          speccond=CA_WQ$Specific_Conductance_Field
)
CategorySpCond <- change.analysis(sites=mysites, subpop=mysubpop, design=mydsgn,
                                  data.cat=mydata.cat,data.cont=mydata.cont, test=c("mean","median"))



# write out specific conductance results
CategorySpCond

write.csv(CategorySpCond$catsum,file='SpCondcatsum.csv')
write.csv(CategorySpCond$contsum_mean,file='SpCondMean.csv')
write.csv(CategorySpCond$contsum_median,file='SpCondMedian.csv')


### Total Nitrogen

TNCAT <- cut(CA_WQ$TN, breaks=c(0,10,10000000), include.lowest=TRUE)
CA_WQ$TNCAT <- TNCAT
CA_WQ$TNCAT <- as.factor(CA_WQ$TNCAT)

mydata.cat <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                         TNcategory=CA_WQ$TNCAT)

mydata.cont <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                          TN=CA_WQ$TN)

#### Total Nitrogen change.analysis

CategoryTNCAT <- change.analysis(sites=mysites, subpop=mysubpop, design=mydsgn,
                                 data.cat=mydata.cat,data.cont=mydata.cont, test=c("mean","median"))

########################################################################
##### write out total nitrogen change analysis results
########################################################################

CategoryTNCAT

write.csv(CategoryTNCAT$catsum,file='TNcatsum.csv')
write.csv(CategoryTNCAT$contsum_mean,file='TNcontsummean.csv')
write.csv(CategoryTNCAT$contsum_median,file='TNcontsummedian.csv')

### Nitrate + Nitrite as N (NOx)


mydata.cont <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION,
                          NOx=CA_WQ$NitrateNitrite_Total_as_N)

#### NOx change.analysis

CategoryNOx <- change.analysis(sites=mysites, subpop=mysubpop, design=mydsgn,
                               data.cont=mydata.cont, test=c("mean","median"))

########################################################################
##### write out NOx change analysis results
########################################################################

CategoryNOx

write.csv(CategoryNOx$contsum_mean,file='NOxcontsummeanC1C3.csv')
write.csv(CategoryNOx$contsum_median,file='NOxcontsummedianC1C3.csv')


### TKN


mydata.cont <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION,
                          TKN=CA_WQ$Kjeldahl_Nitrogen_Total_as_N)

#### TKN change.analysis

CategoryTKN <- change.analysis(sites=mysites, subpop=mysubpop, design=mydsgn,
                               data.cont=mydata.cont, test=c("mean","median"))

########################################################################
##### write out TKN change analysis results
########################################################################

CategoryTKN

write.csv(CategoryTKN$contsum_mean,file='TKNcontsummeanC1C3.csv')
write.csv(CategoryTKN$contsum_median,file='TKNcontsummedianC1C3.csv')

#### Total Phosphorus

mydata.cat <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                         TPcategory=CA_WQ$Phosphorus_Total_as_P)

mydata.cont <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                          TP=CA_WQ$Phosphorus_Total_as_P)

#### Total Phosphorus change.analysis

CategoryTPCAT <- change.analysis(sites=mysites, subpop=mysubpop, design=mydsgn,
                                 data.cat=mydata.cat,data.cont=mydata.cont, test=c("mean","median"))


########################################################################
##### write out total phosphorus change analysis results
########################################################################

CategoryTPCAT

write.csv(CategoryTPCAT$catsum,file='TPcatsum.csv')
write.csv(CategoryTPCAT$contsum_mean,file='TPcontsummean.csv')
write.csv(CategoryTPCAT$contsum_median,file='TPcontsummedian.csv')

#### temperature

mydata.cat <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                         Tempcategory=CA_WQ$Water_Temperature)

mydata.cont <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                          Temp=CA_WQ$Water_Temperature)

#### Water temperature change.analysis

CategoryTemp <- change.analysis(sites=mysites, subpop=mysubpop, design=mydsgn,
                                 data.cat=mydata.cat,data.cont=mydata.cont, test=c("mean","median"))


########################################################################
##### write out water temperature change analysis results
########################################################################

CategoryTemp

write.csv(CategoryTemp$catsum,file='Tempcatsum.csv')
write.csv(CategoryTemp$contsum_mean,file='Tempcontsummean.csv')
write.csv(CategoryTemp$contsum_median,file='Tempcontsummedian.csv')


# pH field

#### pH change.analysis

mydata.cont <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                          pHField=CA_WQ$pH_Field)

CategorypH <- change.analysis(sites=mysites, subpop=mysubpop, design=mydsgn,
                              data.cont=mydata.cont, test=c("mean","median"))


########################################################################
##### write out pH change analysis results
########################################################################

CategorypH

write.csv(CategorypH$contsum_mean,file='pHcontsumMeanC1C3.csv')
write.csv(CategorypH$contsum_median,file='pHcontsumMedianC1C3.csv')


# Dissolved Oxygen

#### Dissolved Oxygen change.analysis

mydata.cont <- data.frame(siteID=CA_WQ$PK_RANDOM_SAMPLE_LOCATION, 
                          DO=CA_WQ$Oxygen_Dissolved_Field)

CategoryDO <- change.analysis(sites=mysites, subpop=mysubpop, design=mydsgn,
                              data.cont=mydata.cont, test=c("mean","median"))


########################################################################
##### write out Dissolved Oxygen analysis results
########################################################################

CategoryDO

write.csv(CategoryDO$contsum_mean,file='DOcontsumMeanC1C3.csv')
write.csv(CategoryDO$contsum_median,file='DOcontsumMedianC1C3.csv')


