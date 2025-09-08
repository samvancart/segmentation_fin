# Script for determining which centroids fall inside conservation areas
# determined by shape files from Syke: https://ckan.ymparisto.fi/dataset/%7BC8FC4A42-A2C3-40C4-92CD-2299C688514E%7D


# SOURCE FILES ------------------------------------------------------------


source("scripts/settings.R")
source("r/utils.R")


# LOAD CONS SHAPE FILES ---------------------------------------------------


cons_dir <- "data/conservation_areas/unzipped/"
cons_files <- list.files(cons_dir, full.names = T, recursive = T, pattern = ".shp$")


# COMBINED SHAPE FILES ----------------------------------------------------


cons_sf_list <- lapply(cons_files, st_read)
cons_sf_list <- lapply(cons_sf_list, function(x) st_transform(x, crs = st_crs(cons_sf_list[[1]]))) # Make sure crs are the same
cons_sf_combined <- do.call(rbind, cons_sf_list)


# GET ALLAS KEYS -------------------------------------------------


data_prefix <- file.path("output/raw/area-ha_dts/")

# Get keys
data_keys_dt <- setnames(as.data.table(list_all_objects_in_bucket(only_keys = T, bucket = bucket, prefix = data_prefix, region = region)), "Key")


# LOAD SEG DATA -----------------------------------------------------------


layer_id <- args$array_id # Choose layer based on array job id

obj <- data_keys_dt$Key[layer_id]
seg_dt <- s3readRDS(object = obj, bucket = bucket, region = region)


# GET CENTROIDS -----------------------------------------------------------


points_sf <- st_as_sf(seg_dt[, c("Id", "x", "y")], coords = c("x", "y"), crs = st_crs(cons_sf_combined))


# ADD CONS ----------------------------------------------------------------


inside <- st_within(points_sf, cons_sf_combined)
seg_dt[, cons_new := lengths(inside) > 0]
seg_dt[, cons_new := as.integer(cons_new)]  # 1 if inside, 0 if not


# SAVE TO ALLAS -----------------------------------------------------------


r_out_name <- paste0("seg_fin_cons_new_", layer_id, ".rds")

obj <- file.path("output", "raw", "cons_new_dts", r_out_name)

print(paste0("Saving ", obj , " into Allas..."))

s3write_using(x = seg_dt,
              FUN = saveRDS,
              object = obj,
              bucket = bucket,
              opts = c(list(multipart = T, region = region)))

print("Done.")





















