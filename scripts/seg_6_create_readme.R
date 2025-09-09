# This script is for programatically creating a readme file.


# SOURCE FILES ------------------------------------------------------------


source("scripts/settings.R")


# DEFINE README LINES -----------------------------------------------------


readme_lines <- c(
  "README: Forest Segment Data Table",
  "",
  "This dataset represents forest segments derived from multi-source biomass rasters and canopy height models",
  "from Finland's 2021 National Forest Inventory. Segments were generated using 10m x 10m resolution data,",
  "reprojected and aggregated based on regional minimum size thresholds.",
  "",
  "Produced by: Natural Resources Institute Finland (Luke)",
  "Funded by: EU Horizon 2020 Programme (Holisoils, Grant No. 101000289)",
  "",
  "Coordinate Reference System (CRS):",
  "----------------------------------",
  "EPSG:3067 — ETRS89 / TM35FIN",
  "",
  "Column Descriptions:",
  "--------------------",
  "segID       : Unique segment identifier / Segmentin tunniste",
  "regName     : Region name / Alueen nimi",
  "N           : Tree density (trees/ha) / Puuston tiheys",
  "ba          : Basal area (m²/ha) / Pohjapinta-ala",
  "age         : Mean tree age (years) / Keskimääräinen ikä",
  "dbh         : Diameter at breast height (cm) / Keskimääräinen läpimitta rinnankorkeudelta",
  "pine        : Proportion of pine trees / Mäntyjen osuus",
  "spruce      : Proportion of spruce trees / Kuusien osuus",
  "decid       : Proportion of deciduous trees / Lehtipuiden osuus",
  "fert        : Site fertility class / Kasvupaikan ravinteisuusluokka (see below)",
  "h           : Mean tree height (dm) / Keskimääräinen pituus",
  "minpeat     : Site type / Kasvupaikan päätyyppi (see below)",
  "landclass   : Land use class / Maankäyttöluokka (see below)",
  "regID       : Region ID / Alueen tunniste",
  "climID      : Climate zone ID / Ilmastovyöhykkeen tunniste",
  "cons        : Conservation status: 1 = conservation area, 0 = not / Suojelustatus",
  "CurrClimID  : Current climate classification ID / Nykyinen ilmastotunniste",
  "area        : Segment area (ha) / Segmentin pinta-ala",
  "x           : X coordinate / X-koordinaatti",
  "y           : Y coordinate / Y-koordinaatti",
  "",
  "Categorical Variables:",
  "-----------------------",
  "landclass (was Maalk):",
  "  1 = Forest land / metsämaa",
  "  2 = Waste land / joutomaa",
  "  3 = Poor forest land / kitumaa",
  "",
  "minpeat (was Ptyyp):",
  "  1 = Mineral soil / mineraalimaa",
  "  2 = Swamp (nutrient-rich) / korpi",
  "  3 = Bog (intermediate) / räme",
  "  4 = Open mire / avosuo",
  "",
  "fert (was Kasp):",
  "  1 = Herb-rich forest / lehto tai vastaava suo",
  "  2 = Herb-rich heath forest / lehtomainen kangas",
  "  3 = Mesic heath forest / tuore kangas",
  "  4 = Sub-xeric heath forest / kuivahko kangas",
  "  5 = Xeric heath forest / kuiva kangas",
  "  6 = Barren heath forest / karukkokangas",
  "  7 = Rock, cliff or sand land / kalliomaa, hietikko tai vesijättömaa",
  "  8 = Highland forest / lakimetsä",
  "  9 = Mountain birch forest / tunturikoivikko",
  " 10 = Open fell tundra / avotunturi",
  "",
  "This README was generated with the help of AI."
)


# SAVE TO ALLAS -----------------------------------------------------------


r_out_name <- paste0("seg_fin_README.txt")

obj <- file.path("output", "clean", r_out_name)

print(paste0("Saving ", obj , " into Allas..."))

s3write_using(x = readme_lines,
              FUN = writeLines,
              object = obj,
              bucket = bucket,
              opts = c(list(multipart = T, region = region)))

print("Done.")














