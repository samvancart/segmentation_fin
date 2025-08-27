
# SOURCE FILES ------------------------------------------------------------


source("scripts/settings.R")
source("r/utils.R")



# LOAD REF DT -------------------------------------------------------------

ref_dt_path <- "data/ref_dt.rds"
ref_dt <- readRDS(ref_dt_path)


# GET ALLAS KEYS -------------------------------------------------


data_prefix <- file.path("output/raw/cons_dts/")

# Get keys
data_keys_dt <- setnames(as.data.table(list_all_objects_in_bucket(only_keys = T, bucket = bucket, prefix = data_prefix, region = region)), "Key")


# LOAD SEG DATA -----------------------------------------------------------


layer_id <- args$array_id # Choose layer based on array job id

obj <- data_keys_dt$Key[layer_id]
seg_dt <- s3readRDS(object = obj, bucket = bucket, region = region)


# area divide by 10000 to get ha
seg_dt[, area_ha := Shape_Area / 10000]

# Species proportions as %
seg_dt[, c("prop_pine", "prop_spruce", "prop_birch") := lapply(.SD, function(x) x * 100), .SDcols = c("prop_pine", "prop_spruce", "prop_birch")]


# SAVE TO ALLAS -----------------------------------------------------------


r_out_name <- paste0("seg_fin_area-ha_", layer_id, ".rds")

obj <- file.path("output", "raw", "area-ha_dts", r_out_name)

print(paste0("Saving ", obj , " into Allas..."))

s3write_using(x = seg_dt,
              FUN = saveRDS,
              object = obj,
              bucket = bucket,
              opts = c(list(multipart = T, region = region)))

print("Done.")























