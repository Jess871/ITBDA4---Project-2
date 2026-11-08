# exploring articles
input_dir <- "Input"

#exploring the folder
files <- list.files(input_dir, full.names = TRUE)
cat("Files in the input directory:\n")
print(files)

#size of files
cat("Size of each file:\n")
file.info(files)$size

#what the documents look like
docs <- lapply(files, readLines, warn = FALSE, encoding = "UTF-8")
names(docs) <- basename(files)
head(docs[["doc1.txt"]], 8)

overview <- data.frame(
  lines = sapply(docs, length),
  blank_lines = sapply(docs, function(d) sum(trimws(d) == "")), 
  words = sapply(docs, function(d) length(unlist(strsplit(paste(d, collapse = " "), "\\s+"))))
)

cat("Overview of the documents:\n")
print(overview)

#headlines
data.frame(headline = sapply(docs, '[', 1))

#anything in the text that could affect the row and column positions
sapply(files, function(f) grepl("\r", readChar(f, file.info(f)$size, useBytes = TRUE), fixed = TRUE))

#special character check
sapply(docs, function(d) sum(grepl("[^ -~]", d)))
unique(unlist(regmatches(unlist(docs), gregexpr("[^ -~]", unlist(docs)))))

#how does the word "africa" appear in the articles
keyword <- "africa"
all_text <- unlist(docs)
table(unlist(regmatches(all_text, gregexpr("[A-Za-z]*africa[A-Za-z]*", all_text, ignore.case = TRUE))))

#expected results from this
expected <- sapply(docs, function(d) {
  m <- gregexpr(keyword, tolower(d), fixed = TRUE)
  sum(sapply(m, function(x) sum(x > 0)))
})

print(expected)
