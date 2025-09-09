# Script to transform the segmentation tables into their final format.


# SOURCE FILES ------------------------------------------------------------


source("scripts/settings.R")
source("r/utils.R")


# GET ALLAS KEYS -------------------------------------------------


data_prefix <- file.path("output/raw/climID_dts/")

# Get keys
data_keys_dt <- setnames(as.data.table(list_all_objects_in_bucket(only_keys = T, bucket = bucket, prefix = data_prefix, region = region)), "Key")


# LOAD SEG DATA -----------------------------------------------------------


layer_id <- args$array_id # Choose layer based on array job id

obj <- data_keys_dt$Key[layer_id]
seg_dt <- s3readRDS(object = obj, bucket = bucket, region = region)


# LOAD LAYER LOOKUP -------------------------------------------------------


layer_lookup_path <- "data/gdb_layers/layer_lookup.csv"
layer_lookup_dt <- fread(layer_lookup_path)


# WRANGLE -----------------------------------------------------------------


# N = number of pixels -> area_ha/0.01
# fert =  sitetype = Kasp
# minpeat =  Ptyyp
# landclass = Maalk
# segID = Id
# grid_coords-clean = CurrClimID
# coordinatesRCPS-clean = climID

# not needed: Wbuffer, pseudoptyp


seg_dt[, regName := layer_lookup_dt[id == layer_id]$layer] # Add original layer name

seg_dt[, N := area_ha/0.01] # Calculate number of trees

new_col_names <- c("segID", "regName", "N", "ba", "age", "dbh", "pine", "spruce", "decid", "fert", "h",
                              "minpeat", "landclass", "regID", "climID", "cons", "CurrClimID", "area", "x", "y")

old_col_names <- c("Id", "regName", "N", "BA", "Age", "Dbh", "prop_pine", "prop_spruce", "prop_birch", "Kasp", "H",
                                "Ptyyp", "Maalk", "reg_id", "coordinatesRCPS-clean", "cons_new", "grid_coords-clean", "area_ha", "x", "y")


seg_dt <- seg_dt[, ..old_col_names]

setnames(seg_dt, old = old_col_names, new = new_col_names)


# SAVE TO ALLAS -----------------------------------------------------------


r_out_name <- paste0("seg_fin_", layer_id, ".rds")

obj <- file.path("output", "clean", "seg_fin_dts", r_out_name)

print(paste0("Saving ", obj , " into Allas..."))

s3write_using(x = seg_dt,
              FUN = saveRDS,
              object = obj,
              bucket = bucket,
              opts = c(list(multipart = T, region = region)))

print("Done.")


















