#Load packages
library(raster)
library(rgdal)
library(snow)
library(snowfall)
library(gdalUtilities)
library(landmap)

#Set working directory
setwd('C:/Users/u0142858/OneDrive - KU Leuven/KUL/PhD/My Project/WP1_Mapping_CB')

#load data
mean_annual_offsetT <- raster('./Data/ForestTempOffsets/mean_annual_offsetT_be.tif')


obj <- GDALinfo("./Data/ForestTempOffsets/mean_annual_offsetT_be.tif")
## tile to 100km blocks:
tile.lst <- getSpatialTiles(obj, block.x=1e5, return.SpatialPolygons=TRUE)
tile.tbl <- getSpatialTiles(obj, block.x=1e5, return.SpatialPolygons=FALSE)
tile.tbl$ID <- as.character(1:nrow(tile.tbl))
head(tile.tbl)
tile.pol <- SpatialPolygonsDataFrame(tile.lst, tile.tbl, match.ID = FALSE)


####Rescale offset values####

#Calculate the 5th and 95th percentile of raster values 
#quantile0.95 <- as.numeric(quantile(mean_annual_offsetT, 0.95, na.rm = TRUE))
#quantile0.05 <- as.numeric(quantile(mean_annual_offsetT, 0.05, na.rm = TRUE))
#quantiles <- as.data.frame(quantile0.05)
#quantiles$quantile0.95 <- quantile0.95
#write.table(quantiles, file = "./OutputOffset/quantile/quantile.txt", sep = "\t",dec = ".",
#            row.names = FALSE, col.names = TRUE)
extremes0.95 <- 2.01
extremes0.05 <- -1.61
####Try to plot one of the tiles.
#i = 6
#m <- rgdal::readGDAL('./Data/ForestTempOffsets/mean_annual_offsetT_be.tif', 
#                     offset=unlist(tile.tbl[i,c("offset.y","offset.x")]),
#                     region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]),
#                     output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]))
#plot(raster(m))


rescale_offsets <- function(i, tile.tbl, out.path = "./OutputOffset/tiled/",
                            mean_annual_offsetT = "./Data/ForestTempOffsets/mean_annual_offsetT_be.tif"){
  out.tif = paste0(out.path, "MIsClimteOffsetMAT_tile", tile.tbl[i,"ID"], ".tif")
  if(!file.exists(out.tif)){
    m <- readGDAL('./Data/ForestTempOffsets/mean_annual_offsetT_be.tif', offset=unlist(tile.tbl[i,c("offset.y","offset.x")]),
                  region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]),
                  output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]),
                  silent = TRUE)
    names(m) <- c("ClimateOffset")
    m <- as(m, "SpatialPixelsDataFrame")
    
    rescale.2 <- m$ClimateOffset
    rescale.2[m$ClimateOffset >= 0 & !is.na(m$ClimateOffset)] = 0
    rescale.2[m$ClimateOffset <= extremes0.05 & !is.na(m$ClimateOffset)] = 1
    rescale.2.min <- min(rescale.2, na.rm = TRUE)
    rescale.3 <- rescale.2 
    
    #Find out maximum value to put in the normalization formula.
    rescale.4 <- rescale.3
    negative_values <- rescale.4[rescale.3 < 0 & !is.na(m$ClimateOffset)]
    Max_normalization<- max(negative_values, na.rm = TRUE) #Maximum value to be used in normalization
    
    #Inverse Normalization formula
    rescale.4[rescale.3 < 0 & !is.na(m$ClimateOffset)] = (Max_normalization - rescale.4[rescale.3 < 0 & !is.na(m$ClimateOffset)])/(Max_normalization - rescale.2.min)
    m$MI <- rescale.4
    writeGDAL(m["MI"], out.tif, 
              options="COMPRESS=DEFLATE")
    rm(list=setdiff(ls(), c("rescale_offsets", "tile.tbl", "mean_annual_offsetT")))
    gc()
  }
}

#test <- rescale_offsets(i= 1,tile.tbl, mean_annual_offsetT = mean_annual_offsetT) #test by selecting one of the tiles.

### Run the normalisation function per tile ###
# Load snowfall, initialize cluster, load libraries and export objects to each core

sfInit(parallel=TRUE, cpus=parallel::detectCores()-2) #parallel::detectCores()
sfExport("rescale_offsets", "tile.tbl", "mean_annual_offsetT", "extremes0.05")
sfLibrary(rgdal)

# Run function to create prediction for each tile 
out.lst <- sfClusterApplyLB(1:nrow(tile.tbl), #nrow(tile.tbl)
                            function(x){ rescale_offsets(x, tile.tbl, mean_annual_offsetT = mean_annual_offsetT) })

# Stop the parallel processing
sfStop() 

### Merge all tiles together to one tiff for Europe ###
# list tiles
t.lst <- list.files("./OutputOffset/tiled/", pattern=".tif", full.names=TRUE)
t.lst <- t.lst[order(nchar(t.lst), t.lst)]
out.tmp <- "./OutputOffset/t_list_MAT.txt"

# Create a virtual 
vrt.tmp <- "./OutputOffset/MIs_ClimateOffset_MAT.vrt"
cat(t.lst, sep="\n", file=out.tmp)


#system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
#system(paste0('gdalwarp ', vrt.tmp, 
#              ' \"./OutputOffset/data/MIs_MAT.tif\" ', 
#              '-ot \"Int16\" -dstnodata \"-32767\" -co \"BIGTIFF=YES\" ',  
#              '-multi -wm 2000 -co \"COMPRESS=DEFLATE\" -overwrite ',
#              '-r \"near\" -wo \"NUM_THREADS=ALL_CPUS\"')) 
##[1] 127

# Path to final map
final <- paste0("./OutputOffset/Output_tif/", "MIs_ClimateOffset",  "_MAT.tif")
gdalbuildvrt(t.lst, output.vrt = vrt.tmp)
gdalwarp(vrt.tmp, final, 
         co = c("BIGTIFF=YES", "COMPRESS=DEFLATE"),
         multi = TRUE, overwrite = TRUE,
         wo = "NUM_THREADS=11")

##Plot the offsets and Microrefugia indices
png(filename = "./OutputOffset/FiguresPlot/MIs_ClimateOffsetsMAT_EU.png", width = 700, height = 500)
par(mfrow=c(1,2))
plot(mean_annual_offsetT, main = 'Mean annual temperature offsets')
MIs <- raster('E:\\Outputs\\Offset\\tif\\MIs_ClimateOffset_MAT.tif')
plot(MIs, main = 'Microrefugia indices of MAT Offsets')
dev.off()

# Delete all seperate part files to save memory
f <- list.files("./OutputOffset/tiled/", include.dirs = F, full.names = T, recursive = T)
## remove the files
file.remove(f)
file.remove("/vsc-hard-mounts/leuven-data/348/vsc34871/ClimateOffset/Output/MIs_ClimateOffset_MAT.vrt")
file.remove("/vsc-hard-mounts/leuven-data/348/vsc34871/ClimateOffset/Output/t_list_MAT.txt")

rm(list=setdiff(ls(), c("rescale_offsets", "tile.tbl", "mean_annual_offsetT")))
gc()


toc(log = TRUE, quiet = TRUE)
log.txt <- tic.log(format = TRUE)
log.lst <- tic.log(format = FALSE)
tic.clearlog

##Check by histogram.
#hist(rescale.3)
#hist(rescale.4)
#
#hist_rescal4 <- hist(rescale.4,
#                     main = "Mean annual offset values rescale",
#                     xlab = "Microrefugia Indices",
#                     ylab= "Frequency",
#                     col = "aquamarine3",
#                     xlim = c(0, 1),
#                     xaxt = 'n')
#axis(side = 1, at = seq(0,1, 0.1), labels = seq(0,1, 0.1))
#
#####Check the data
#cellStats(rescale.4, "max")
##Max = 1
#
#cellStats(rescale.4, "min") 
##min = 0
#
##check the number of cells with value 0. rescale.3 should 
##have higher frequency of cell value 0 and 1 than rescale.1.
#freq(rescale.4, value = 0)
#freq(rescale.3, value = 0)
