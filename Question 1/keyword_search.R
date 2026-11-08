#hadoop mapreduce 
options(width = 150)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) >= 1) {
  keyword <- args[1]
} else {
  keyword <- readline("Enter the keyword to search for: ")
}
if (trimws(keyword) == "") stop("No keyword supplied.")

output_dir <- file.path(getwd(), "output")
hadoop_home <- Sys.getenv("HADOOP_HOME")

cat("Keyword:", keyword, "\n")

#configuration
job_settings <- c(
  paste0("mapreduce.job.name=keyword_search_", keyword),
  "mapreduce.job.reduces=1",
  "mapreduce.input.fileinputformat.split.minsize=9223372036854775807",
  "stream.num.map.output.key.fields=1"
)

hadoop <- file.path(hadoop_home, "bin", "hadoop.cmd")
streaming_jar <- list.files(file.path(hadoop_home, "share", "hadoop", "tools", "lib"), 
                            pattern = "hadoop-streaming.*.jar", full.names = TRUE)[1]


#dont overwrite existing output directory
unlink(output_dir, recursive = TRUE)

hadoop_args <- c(
  "jar", streaming_jar,
  "-fs", dQuote("file:///", FALSE),
  "-jt", "local",
  as.vector(rbind("-D", dQuote(job_settings, FALSE))),
  "-files", dQuote("mapper.R,reducer.R", FALSE),
  "-input", "Input",
  "-output", "output",
  "-mapper", dQuote("Rscript mapper.R", FALSE),
  "-reducer", dQuote("Rscript reducer.R", FALSE),
  "-cmdenv", dQuote(paste0("KEYWORD=", keyword), FALSE)
)

status <- system2(hadoop, hadoop_args)
if (status !=0) stop("Hadoop streaming job failed.")
results <- readLines(file.path(output_dir, "part-00000"))

if (length(results) == 0) {
  cat("No occurrences of the keyword '", keyword, "' found in the documents.\n", sep = "")
} else {
 parts <- strsplit(results, "\t")
 results_df <- data.frame(
   document = sapply(parts, `[`, 1),
   matches = as.integer(sapply(parts, `[`, 2)),
   locations = sapply(parts, `[`, 3)
)

cat("Keyword search results for '", keyword, "':\n", sep = "")
print(results_df, row.names=FALSE)
} 