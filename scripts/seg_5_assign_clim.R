# Script for assigning climIDs to segmented data.

# SOURCE FILES ------------------------------------------------------------


source("scripts/settings.R")
source("r/utils.R")


# LOAD CLIM FILES ---------------------------------------------------------


clim_dir <- "data/climate"
clim_paths <- list.files(clim_dir, full.names = T, pattern = ".csv")
clim_files_list <- lapply(clim_paths, fread)
clim_names <- unlist(tstrsplit(as.list(basename(clim_paths)), split = "\\.", keep = 1), recursive = F)
clim_files_list <- setNames(clim_files_list, clim_names)


# GET ALLAS KEYS -------------------------------------------------


data_prefix <- file.path("output/raw/regID_dts/")

# Get keys
data_keys_dt <- setnames(as.data.table(list_all_objects_in_bucket(only_keys = T, bucket = bucket, prefix = data_prefix, region = region)), "Key")


# LOAD SEG DATA -----------------------------------------------------------


layer_id <- args$array_id # Choose layer based on array job id

obj <- data_keys_dt$Key[layer_id]
seg_dt <- s3readRDS(object = obj, bucket = bucket, region = region)

















