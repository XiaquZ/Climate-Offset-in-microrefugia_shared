#Load packages
library("sp", lib.loc = "/vsc-hard-mounts/leuven-data/348/vsc34871/Rlib/4.0.2-foss-2018a/") #error when loading raster
library("iterators",lib.loc = "/vsc-hard-mounts/leuven-data/348/vsc34871/Rlib/4.0.2-foss-2018a/") # Otherwise error when loading doParallel
library("codetools",lib.loc = "/vsc-hard-mounts/leuven-data/348/vsc34871/Rlib/4.0.2-foss-2018a/") # Otherwise error when loading raster
library("sf",lib.loc = "/vsc-hard-mounts/leuven-data/348/vsc34871/Rlib/4.0.2-foss-2018a/")# Otherwise error when loading gdalUtilities
library('raster',lib.loc = "/vsc-hard-mounts/leuven-data/348/vsc34871/Rlib/4.0.2-foss-2018a/")
library('rgdal',lib.loc = "/vsc-hard-mounts/leuven-data/348/vsc34871/Rlib/4.0.2-foss-2018a/")


#load data
mean_annual_offsetT <- raster('/lustre1/scratch/348/vsc34871/input/ForestTempNew/Offsets/mean_annualOffset.tif')


####Extra the 5th and 95th quantile value for normalization later####
#Calculate the 5th and 95th percentile of raster values 

quantile0.95 <- as.numeric(quantile(mean_annual_offsetT, 0.95, na.rm = TRUE))
quantile0.05 <- as.numeric(quantile(mean_annual_offsetT, 0.05, na.rm = TRUE))
quantiles <- as.data.frame(quantile0.05)
quantiles$quantile0.95 <- quantile0.95
write.table(quantiles, file = "/vsc-hard-mounts/leuven-data/348/vsc34871/ClimateOffset/Output/Quantiles/MAT_quantile_new.txt", sep = "\t",dec = ".",
            row.names = FALSE, col.names = TRUE)