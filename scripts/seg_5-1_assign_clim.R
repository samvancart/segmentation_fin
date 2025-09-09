# Script for assigning climIDs to segmented data. 
# Preprocess climID lookups in seg_5-0_clean_clim.R first.


# SOURCE FILES ------------------------------------------------------------


source("scripts/settings.R")
source("r/utils.R")


# LOAD CLIM FILES ---------------------------------------------------------


clim_dir <- "data/climate/clean"
clim_paths <- list.files(clim_dir, full.names = T, pattern = ".csv")
clim_files_list <- lapply(clim_paths, fread)
clim_names <- unlist(tstrsplit(as.list(basename(clim_paths)), split = "\\.", keep = 1), recursive = F)
clim_files_list <- setNames(clim_files_list, clim_names)


# GET ALLAS KEYS -------------------------------------------------


data_prefix <- file.path("output/raw/cons_new_dts/")

# Get keys
data_keys_dt <- setnames(as.data.table(list_all_objects_in_bucket(only_keys = T, bucket = bucket, prefix = data_prefix, region = region)), "Key")


# LOAD SEG DATA -----------------------------------------------------------


layer_id <- args$array_id # Choose layer based on array job id

obj <- data_keys_dt$Key[layer_id]
seg_dt <- s3readRDS(object = obj, bucket = bucket, region = region)


# FIND NEAREST NEIGHBOURS -------------------------------------------------


climIDs_list <- lapply(names(clim_files_list), function(name) {
  data_dt <- clim_files_list[[name]]
  knn_mat <- seg_find_kNN(data_dt = data_dt, query_dt = seg_dt, is_lonlat = FALSE)
  knn_dt <- as.data.table(knn_mat)
  setnames(knn_dt, name)
})


# BIND TO SEG_DT ----------------------------------------------------------


combined_climIDs_dt <- do.call(cbind, climIDs_list)
seg_dt_climID <- cbind(seg_dt, combined_climIDs_dt)


# SAVE TO ALLAS -----------------------------------------------------------


r_out_name <- paste0("seg_fin_clim_", layer_id, ".rds")

obj <- file.path("output", "raw", "climID_dts", r_out_name)

print(paste0("Saving ", obj , " into Allas..."))

s3write_using(x = seg_dt_climID,
              FUN = saveRDS,
              object = obj,
              bucket = bucket,
              opts = c(list(multipart = T, region = region)))

print("Done.")

















