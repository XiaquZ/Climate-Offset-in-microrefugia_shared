####Calculate mean of minimum temp offsets.
library("codetools",lib.loc = "/vsc-hard-mounts/leuven-data/348/vsc34871/Rlib/4.0.2-foss-2018a/") # Otherwise error when loading raster
library("sp", lib.loc = "/vsc-hard-mounts/leuven-data/348/vsc34871/Rlib/4.0.2-foss-2018a/") #error when loading raster
library("raster", lib.loc = "/vsc-hard-mounts/leuven-data/348/vsc34871/Rlib/4.0.2-foss-2018a/")
library("iterators",lib.loc = "/vsc-hard-mounts/leuven-data/348/vsc34871/Rlib/4.0.2-foss-2018a/") # Otherwise error when loading doParallel
library('parallel',lib.loc = "/vsc-hard-mounts/leuven-data/348/vsc34871/Rlib/4.0.2-foss-2018a/")

##Calculate the average of minimum Temp offsets during winter and spring.

datasets <- c('/lustre1/scratch/348/vsc34871/input/ForestTempNew/Offsets/Minimum/ForestTemp_minT_offset_12.tif',
              '/lustre1/scratch/348/vsc34871/input/ForestTempNew/Offsets/Minimum/ForestTemp_minT_offset_01.tif',
              '/lustre1/scratch/348/vsc34871/input/ForestTempNew/Offsets/Minimum/ForestTemp_minT_offset_02.tif',
              '/lustre1/scratch/348/vsc34871/input/ForestTempNew/Offsets/Minimum/ForestTemp_minT_offset_03.tif',
              '/lustre1/scratch/348/vsc34871/input/ForestTempNew/Offsets/Minimum/ForestTemp_minT_offset_04.tif',
              '/lustre1/scratch/348/vsc34871/input/ForestTempNew/Offsets/Minimum/ForestTemp_minT_offset_05.tif')
output_vector <- mclapply(datasets, raster)
output_stack <- stack(output_vector)
mean_test <- mclapply(output_stack,mean)

writeRaster(mean_min, filename = "/lustre1/scratch/348/vsc34871/output/mean_OffsetMinTemp_WinterSpring_new.tif", overwrite = TRUE)

