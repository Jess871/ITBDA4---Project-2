# reducer
current_doc <- NULL
locations <- c()

write_result <- function(doc, locs) {
  rc <- do.call(rbind, strsplit(locs, ","))
  locs <- locs[order(as.integer(rc[, 1]), as.integer(rc[, 2]))]
  cat(doc, "\t", length(locs), "\t", paste0("(", locs, ")", collapse = " "), "\n", sep = "")
}

con <- file("stdin", open = "r")

while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0) {
  parts <- strsplit(line, "\t")[[1]]
  doc <- parts[1]
  location <- sub("\r$", "", parts[2])
  
  if (!is.null(current_doc) && doc != current_doc) {
    write_result(current_doc, locations)
    locations <- c()
  }
  current_doc <- doc
  locations <- c(locations, location)
}

if (!is.null(current_doc)) write_result(current_doc, locations)
close(con)