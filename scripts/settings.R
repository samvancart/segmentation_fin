
# LOAD LIBS ---------------------------------------------------------------


require(sf)
require(data.table)
require(optparse)
require(aws.s3)


# PARSE ARGS --------------------------------------------------------------


option_list <- list(
  make_option(c("-a", "--array_id"), type="integer", default=as.integer(Sys.getenv("SLURM_ARRAY_TASK_ID", unset = 1)), 
              help="SLURM array job ID [default: %default]"),
  
  make_option(c("-c", "--array_count"), type="integer", default=as.integer(Sys.getenv("SLURM_ARRAY_TASK_COUNT", unset = 1)), 
              help="Total number of array jobs [default: %default]")
)

parser <- OptionParser(option_list=option_list)
args <- parse_args(parser)

print("Array id:")
print(args$array_id)
print("Max arrays:")
print(args$array_count)


# ALLAS ENV VARS ----------------------------------------------------------


bucket <- Sys.getenv("AWS_BUCKET")
region <- Sys.getenv("AWS_REGION")









