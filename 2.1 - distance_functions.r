##############################
################################
#################################
## WARNING - this distance function takes a long time to run. Depending on the resolution of your base raster, it can take up to 5 hours on a fast machine.  
##############################
############################
##############################


##Step 1 - Load librarires



require(raster)
require(rgeos)
require(sf)
require(rgdal)
library(tidyverse)

## Step 1.2 - Specify all variables

## Raster file should include file extension. 
### This file will be the base raster, it will determine the dimensions of the model and all resulting layers created by this function.
raster_base_file_path<-"inputs/raster/Elevation_100.tif"
## File path to extent polygon
extent_file_path<-"inputs/shape/extent/little_snake_fo_extent"
## Specify where you want the resulting distance rasters to go.  The folder should already exist!!!!!!
### All outputs for the model should be the same. 
output_file_path<-"test/output/distance_calc2"
##distance_to_shape("rData/poly/species_data", single_shapefile_dist_to_poly)
input_file_path<-"test/lines_test"



# Step 2 - Create base_dem for clip feature
dem<-raster(raster_base_file_path)%>%
  crop(extent(st_read(dirname(extent_file_path),  basename(extent_file_path))))%>%
  aggregate(fact=10)


## Step 3 - Function to read all line files. 

distance_to_shape<-function(folder_of_shapefiles, specified_function, base_dem){
  t<-base::list.files(folder_of_shapefiles)
  t1<-vector()
  for(i in t){
    t1<-append(t1, strsplit(i, "\\.")[[1]][1])
  }
  t<- base::unique(t1)
  t1<-folder_of_shapefiles
  t2<-base_dem
  f<-specified_function
  lapply(t, f, t1, t2)
}




## Step 4 - Distanc Calc: works for both poly and line features =
shape_distance_to_raster<-function(shape_file_name, shape_file_path, base_dem){
  
  t_shape<-st_read(dsn=shape_file_path, layer=shape_file_name)%>%
    st_crop(extent(base_dem))
  
  t_raster<-raster(ext=extent(base_dem),
                   crs=st_crs(t_shape)$proj4string,
                   res=res(base_dem)
  )
  
  t_raster<-setValues(t_raster, 0)
  
    
  t_raster_masked<-mask(t_raster, t_shape)
  raster_distance<-distance(t_raster_masked)
  rm(t_raster_masked)
  writeRaster(raster_distance, filename=paste0(output_file_path, "/distance_calc_",
                                               shape_file_name,".grd"),
              format='raster', overwrite=TRUE)
  
  rm(raster_distance)
  
}


# How to run the function
## inputs are: 
#   -input file path specified above
#   -function to be applied to all of the poly and line features
#   -The clip dem that we created above from the base dem and extent of the fo. 

s_time<-Sys.time()

distance_to_shape(input_file_path, shape_distance_to_raster, dem)

e_time<-Sys.time()

e_time-s_time