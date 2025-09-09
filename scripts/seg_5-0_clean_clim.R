# Script for cleaning climate data lookup tables for processing in seg_5-1_assign_clim.R.


# SOURCE FILES ------------------------------------------------------------


source("scripts/settings.R")
source("r/utils.R")


# LOAD CLIM FILES ---------------------------------------------------------


clim_dir <- "data/climate/raw"
clim_paths <- list.files(clim_dir, full.names = T, pattern = ".csv")
clim_files_list <- lapply(clim_paths, fread)
clim_names <- unlist(tstrsplit(as.list(basename(clim_paths)), split = "\\.", keep = 1), recursive = F)
clim_files_list <- setNames(clim_files_list, clim_names)



# CLEAN coordinatesRCPS ---------------------------------------------------


coordinatesRCPS <- clim_files_list[[1]]
coordinatesRCPS_proj_dt <- as.data.table(seg_project_coords(coordinatesRCPS, lon_col = "x", lat_col = "y"))
coordinatesRCPS_all <- cbind(coordinatesRCPS, coordinatesRCPS_proj_dt)
setnames(coordinatesRCPS_all, c("lon", "lat", "id", "x", "y"))
setcolorder(coordinatesRCPS_all, c("id", "x", "y", "lon", "lat"))

fwrite(coordinatesRCPS_all, "data/climate/clean/coordinatesRCPS-clean.csv")


# CLEAN grid_coords -------------------------------------------------------


grid_coords <- clim_files_list[[2]]
grid_coords_proj_dt <-  as.data.table(seg_project_coords(grid_coords, lon_col = "long_deg", lat_col = "lat_deg"))
grid_coords[, c("longitude", "latitude") := NULL]
grid_coords_all <- cbind(grid_coords, grid_coords_proj_dt)
setnames(grid_coords_all, c("id", "lon", "lat", "x", "y"))
setcolorder(grid_coords_all, c("id", "x", "y", "lon", "lat"))

fwrite(grid_coords_all, "data/climate/clean/grid_coords-clean.csv")















