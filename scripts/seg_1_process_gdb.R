# This script is for processing segmentation_fin_zip that contains segments of forested area
# in Finland as gdb files (multipolygons). Link: https://zenodo.org/records/11360322.
# The unpacked gdb files are read (1 layer per array job) after which the centroid for each 
# multipolygon is calculated. A reg_id is then assigned to each centroid.
# The reg_id indicates the Finnish region that a centroid falls into.
# The species proportions (Pine, spruce, birch) are then calculated based on total volume. 
# Birch proportion is birch + other deciduous.
# The result is saved into Allas using the aws.s3 package.  


# SOURCE FILES ------------------------------------------------------------


source("scripts/settings.R")


# LOAD GDB ----------------------------------------------------------------


gdb_path <- "data/kuviointi.gdb"

available_gdb_layers <- st_layers(gdb_path) # List layers

layer_id <- args$array_id # Choose layer based on array job id

layer <- available_gdb_layers$name[layer_id]

# Read layer as sf
seg_data_sf <- st_read(gdb_path, layer = layer)


# LOAD REGION FIN DATA ----------------------------------------------------


regions_fin_path <- "data/regions_fin/"

regions_fin_sf <- st_read(regions_fin_path)


# SET CRS -----------------------------------------------------------------


seg_data_sf <- st_set_crs(seg_data_sf, st_crs(regions_fin_sf)) # Set CRS to EPSG:3067 (ETRS-TM35FIN) from regions_fin_sf


# GDB TO CENTROIDS --------------------------------------------------------


seg_data_sf_centroids <- st_centroid(seg_data_sf) # Multipolygon to centroids


# ASSIGN REGION IDS TO CENTROIDS ------------------------------------------


regions_fin_cols <- c("reionID") # Columns to keep

regIDs_sf <- regions_fin_sf[, regions_fin_cols] # Filter table

# Spatial join: find which polygon each centroid falls into
seg_data_sf_regIds <- st_join(seg_data_sf_centroids, regIDs_sf, join = st_within)



# TO DATA TABLE -----------------------------------------------------------


coords <- as.data.table(st_coordinates(seg_data_sf_regIds))
seg_data_sf_regIds$x <- coords[, "X"]
seg_data_sf_regIds$y <- coords[, "Y"]

dt <- as.data.table(st_drop_geometry(seg_data_sf_regIds))


# CALCULATE SPECIES PROPORTIONS -------------------------------------------


dt[, t_vol := Vol_ma + Vol_ku + Vol_ko + Vol_mlp] # Calculate actual total volume

dt[, vol_b_dec := Vol_ko + Vol_mlp] # Calculate birch + deciduous

# Get proportions. Set to 0 when t_vol = 0
dt[, c("prop_pine", "prop_spruce", "prop_birch") := .(
  fifelse(t_vol > 0, Vol_ma / t_vol, 0),
  fifelse(t_vol > 0, Vol_ku / t_vol, 0),
  fifelse(t_vol > 0, vol_b_dec / t_vol, 0)
)]


dt[, c("t_vol", "vol_b_dec") := NULL] # Remove helper cols

setnames(dt, old = "reionID", "reg_id") # Rename


# SAVE TO ALLAS -----------------------------------------------------------


r_out_name <- paste0("seg_fin_regID_", layer_id, ".rds")

obj <- file.path("output", "raw", "regID_dts", r_out_name)

print(paste0("Saving ", obj , " into Allas..."))

s3write_using(x = dt,
              FUN = saveRDS,
              object = obj,
              bucket = bucket,
              opts = c(list(multipart = T, region = region)))

print("Done.")



























