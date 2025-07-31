


# SOURCE FILES ------------------------------------------------------------


source("scripts/settings.R")


# LOAD GDB ----------------------------------------------------------------

gdb_path <- "data/kuviointi.gdb"

# List layers
available_gdb_layers <- st_layers(gdb_path)


layer <- available_gdb_layers$name[1]

# Read a specific layer
data <- st_read(gdb_path, layer = layer)


