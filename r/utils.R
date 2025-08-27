# Utility functions



# LOAD_RDATA --------------------------------------------------------------



#' Load R Data File
#'
#' This function loads an R data file into a new environment and returns the object.
#'
#' @param rdata_file_path The path to the R data file to be loaded.
#'
#' @return Returns the object loaded from the rdata_file_path.
#'
#' @examples
#' # Assuming 'data.RData' contains an object named 'my_data'
#' my_data <- load_rdata_file('data.RData')
#'
#' @export
load_rdata_file <- function(rdata_file_path) {
  assertFileExists(rdata_file_path, access = "r")
  temp_env <- new.env()
  obj <- get(load(rdata_file_path), temp_env)
  return(obj)
}



# GROUP_AND_JOIN_DTS ------------------------------------------------------




#' Create a Grouped Data Table from Filenames
#'
#' This function takes a vector of filenames and splits them into a data table based on specified column names and grouping variables.
#'
#' @param filenames A character vector of filenames.
#' @param column_names A character vector of column names to assign to the split components of the filenames. The last column name will usually be the file extension.
#' @param group_vars A character vector of column names to group by.
#' @param sep A character string specifying the separator pattern used to split the filenames. Default is "[_]".
#' @param base_path An optional character string specifying the base path to prepend to the filenames.
#' 
#' @return A data.table with the split components of the filenames, an `id` column for grouping, and a `filename` column with the full path if `base_path` is provided.
#' @export
#'
#' @examples
#' filenames <- c("sample_1.txt", "sample_2.txt")
#' column_names <- c("sample", "number")
#' group_vars <- c("sample")
#' get_grouped_dt_from_filenames(filenames, column_names, group_vars)
#'
#' # Example with base_path
#' get_grouped_dt_from_filenames(filenames, column_names, group_vars, base_path = "/path/to/files")
#'
#' # Edge case: Different separator
#' filenames <- c("sample-1.txt", "sample-2.txt")
#' get_grouped_dt_from_filenames(filenames, column_names, group_vars, sep = "[-]")
#'
#' # Edge case: No filenames
#' get_grouped_dt_from_filenames(character(0), column_names, group_vars)
#' 
#' @import data.table
#' @import stringr
#' @import tools
#' @import checkmate
get_grouped_dt_from_filenames <- function(filenames, column_names, group_vars, sep = "[_]", base_path = NULL) {
  # Validate inputs
  assert_character(filenames, min.len = 1)  # Ensure filenames is a non-empty character vector
  assert_character(column_names, min.len = 1)  # Ensure column_names is a non-empty character vector
  assert_character(group_vars, min.len = 1)  # Ensure group_vars is a non-empty character vector
  assert_string(sep)  # Ensure sep is a single string
  assert_string(base_path, null.ok = TRUE)  # Ensure base_path is a single string or NULL
  
  # Remove file extensions using file_path_sans_ext from tools
  filenames_no_ext <- file_path_sans_ext(filenames)
  
  # Split filenames into a data table based on the separator
  dt <- as.data.table(str_split_fixed(filenames_no_ext, sep, length(column_names)))
  colnames(dt) <- column_names  # Assign column names to the data table
  
  # Create a grouping ID based on the specified grouping variables
  dt[, id := .GRP, by = group_vars]
  
  # Prepend base_path to filenames if base_path is provided
  if (!is.null(base_path)) {
    filenames <- file.path(base_path, filenames)
  }
  
  # Add the filenames (with base_path if provided) to the data table
  dt[, filename := filenames]
  
  return(dt)  # Return the resulting data table
}


#' Process and Join Data Tables
#'
#' This function processes a data.table by applying a specified function to a variable and then joins the results.
#'
#' @param dt A data.table object.
#' @param fun A function to apply to the variable specified by `process_var_name`.
#' @param fun_args A list of additional arguments to pass to `fun`.
#' @param process_var_name A character string specifying the name of the variable to process.
#' @param join_by_vec A character vector specifying the columns to join by.
#'
#' @return A data.table resulting from the processing and joining operations.
#' @export
#'
#' @examples
#' library(data.table)
#' dt <- data.table(id = 1:3, value = list(1:2, 3:4, 5:6))
#' fun <- function(x, add) { data.table(result = x + add) }
#' fun_args <- list(add = 10)
#' process_from_grouped_dt_and_join(dt, fun, fun_args, "value", "result")
process_from_grouped_dt_and_join <- function(dt, FUN, FUN_args, process_var_name, join_by_vec) {
  
  # Input validations using checkmate
  assert_data_table(dt)
  assert_function(FUN)
  assert_list(FUN_args)
  assert_string(process_var_name)
  assert_character(join_by_vec)
  
  result_dt <- dt[, {
    processed_list <- lapply(get(process_var_name), function(var) {
      args_list <- c(list(var), FUN_args)
      do.call(FUN, args_list)
    })
    Reduce(function(x, y) full_join(x, y, by = join_by_vec), processed_list)
  }]
  
  return(result_dt)
}



# SPLIT_DT ----------------------------------------------------------------




#' Split Data Table into Equal Parts with Constraint
#'
#' This function splits a data table into approximately equal parts based on a specified constraint.
#'
#' @param dt A data.table object to be split.
#' @param max_part_size An integer specifying the maximum size of each part.
#' @param split_by_constraint A character vector specifying the column(s) to split by.
#' @param split_id_name A character string specifying the name of the split ID column. Default is "splitID".
#' @param verbose Logical indicating whether to display info about the split operation or not. Default is TRUE.
#' @return A data.table object with an additional column indicating the part each row belongs to.
#' @import data.table
#' @import checkmate
#' @export
#' @examples
#' library(data.table)
#' dt <- data.table(id = 1:100, value = rnorm(100))
#' split_dt_equal_with_constraint(dt, max_part_size = 10, split_by_constraint = "id", split_id_name = "partID")
split_dt_equal_with_constraint <- function(dt, max_part_size, split_by_constraint, split_id_name = "splitID", verbose = TRUE) {
  
  # Input validation
  assert_data_table(dt)
  assert_integerish(max_part_size, lower = 1, len = 1)
  assert_character(split_by_constraint, min.len = 1)
  assert_names(names(dt), must.include = split_by_constraint)
  assert_string(split_id_name)
  assert_logical(verbose)
  
  # Get dt of unique IDs
  unique_ids <- unique(dt[, ..split_by_constraint])
  
  # Get number of IDs
  n_ids <- nrow(unique_ids)
  
  mod <- n_ids %% max_part_size
  
  adjusted_max_part_size <- ifelse(mod == 0, max_part_size, pmax(1, max_part_size - 1))
  
  # Number of parts to split dt into
  n_split_parts <- ifelse(n_ids/adjusted_max_part_size <= 1, 1, ceiling(n_ids/adjusted_max_part_size))
  
  if(verbose) {
    print(paste0("Splitting ", n_ids, " unique id(s) into ", n_split_parts, " part(s)."))
  }
  
  # Assign splitIDs
  if (n_split_parts == 1) {
    unique_ids[, (split_id_name) := 1]
  } else {
    unique_ids[, (split_id_name) := cut(seq_len(.N), breaks = n_split_parts, labels = FALSE)]
  }
  
  # Merge splitIDs into original dt
  dt <- merge(dt, unique_ids, by = split_by_constraint)
  
  return(dt)
}

# AWS -------------------------------------------------------------

# Function to list all objects in an S3 bucket 1000 at a time 
# (the maximum in the aws.s3 package get_bucket function).
# If there are more than 1000 objects then they a collected in a loop by moving
# the marker param to start from the end of the last batch of fetched objects.
#
# Returns a list of the aws.s3 objects that were found or a character vector of 
# the unique keys of the objects when only_keys=TRUE
list_all_objects_in_bucket <- function(only_keys = F, ...) {
  all_objects <- list()
  marker <- NULL
  total_objects <- 0
  
  while(TRUE) {
    
    
    # Retrieve a batch of objects
    batch <- get_bucket(marker = marker, max = 1000, ...)
    
    total_objects <- total_objects + length(batch)
    
    # Update the marker to the last key in the current batch
    marker <- tail(batch, 1)$Contents$Key
    
    # If no more objects are returned, break the loop
    if (length(batch) == 0 | is.null(marker)) break
    
    # Append the batch to the list of all objects
    all_objects <- c(all_objects, batch)
    
  }
  
  print(paste0("Found a total of ", total_objects, " objects."))
  
  obj <- unique(rbindlist(all_objects), by = "Key")
  
  if(only_keys) return(obj$Key)
  
  return(obj)
}



