# Script for determining which centroids fall inside conservation areas.
# A "cons" column is added to the data.table containing the segment info with
# value 1 = conservation area and 0 = not a conservation area.
# Run as array job.


# SOURCE FILES ------------------------------------------------------------


source("scripts/settings.R")
source("r/utils.R")


# LOAD CONS RASTER --------------------------------------------------------


cons_raster_path <- "data/consAreasNew.tif"
cons_raster <- rast(cons_raster_path)


# GET ALLAS KEYS -------------------------------------------------


data_prefix <- file.path("output/raw/regID_dts/")

# Get keys
data_keys_dt <- setnames(as.data.table(list_all_objects_in_bucket(only_keys = T, bucket = bucket, prefix = data_prefix, region = region)), "Key")


# LOAD SEG DATA -----------------------------------------------------------


layer_id <- args$array_id # Choose layer based on array job id

obj <- data_keys_dt$Key[layer_id]
seg_dt <- s3readRDS(object = obj, bucket = bucket, region = region)


# SPAT VEC FROM CENTROIDS -------------------------------------------------


# Create SpatVector from centroids
centroids <- vect(seg_dt[, c("Id", "x", "y")], geom = c("x", "y"), crs = "EPSG:3067")

# Transform to raster CRS
centroids_utm <- project(centroids, crs(cons_raster))


# ADD CONS ----------------------------------------------------------------


# Extract values
vals <- extract(cons_raster, centroids_utm)

# Add binary column to data.table
seg_dt[, cons := ifelse(!is.na(vals[,2]), 1, 0)]


# SAVE TO ALLAS -----------------------------------------------------------


r_out_name <- paste0("seg_fin_cons_", layer_id, ".rds")

obj <- file.path("output", "raw", "cons_dts", r_out_name)

print(paste0("Saving ", obj , " into Allas..."))

s3write_using(x = seg_dt,
              FUN = saveRDS,
              object = obj,
              bucket = bucket,
              opts = c(list(multipart = T, region = region)))

print("Done.")





















