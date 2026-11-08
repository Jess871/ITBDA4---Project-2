# Mapper function for MapReduce
keyword <- tolower(Sys.getenv("KEYWORD"))
if (keyword == "") stop("No keyword supplied.")

#store path of file being read
doc_name <- basename(Sys.getenv("mapreduce_map_input_file", unset = "unknown"))

con <- file("stdin", open = "r")
row <- 0

while (length(line <- readLines(con, n = 1, warn = FALSE, encoding = "UTF-8")) > 0) {
  row <- row + 1
  matches <- gregexpr(keyword, tolower(line), fixed = TRUE)[[1]]
  
  if (matches[1] != -1) {
    for (col in matches) {
      cat(doc_name, "\t", row, ",", col, "\n", sep = "")
    }
  }
}
close(con)