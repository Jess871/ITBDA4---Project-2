# Question 2.1
library(tm)

#file path
setwd("C:/Users/jessb/OneDrive/Desktop/University/University/CTI/Honours/Semester 2/ITBDA4/Assignment/Question 2")

load_corpus <- function(data_dir) {
  files <- list.files(data_dir, pattern = "\\.txt$", full.names = TRUE)
  files <- files[order(as.integer(gsub("\\D", "", basename(files))))]
  content <- vapply(files, function(f) paste(readLines(f, warn = FALSE), collapse = " "), character(1))
  data.frame(file_name = basename(files), content = content, stringsAsFactors = FALSE)
}
  
#data loading
df <- load_corpus("C:/Users/jessb/OneDrive/Desktop/University/University/CTI/Honours/Semester 2/ITBDA4/Assignment/ITBDA4-14 Project 2 Datasets-20260722/news/sa_news")

#creating corpus
corpus <- Corpus(VectorSource(df$content))

#normalise text
corpus <- tm_map(corpus, content_transformer(function(x) gsub("[\u2013-]?\\s*SANews\\.gov\\.za", " ", x, ignore.case = TRUE)))
corpus <- tm_map(corpus, content_transformer(function(x) gsub("[\u2018\u2019]", "'", x)))
corpus <- tm_map(corpus, content_transformer(function(x) gsub("[\u201C\u201D]", '"', x)))
corpus <- tm_map(corpus, content_transformer(function(x) gsub("[\u2013\u2014]", " ", x)))
corpus <- tm_map(corpus, content_transformer(function(x) gsub("\u2022", " ", x)))

# text cleaning
corpus <- tm_map(corpus, content_transformer(tolower))
corpus <- tm_map(corpus, removeWords, stopwords("english"))
corpus <- tm_map(corpus, removeNumbers)
corpus <- tm_map(corpus, removePunctuation)
corpus <- suppressWarnings(tm_map(corpus, stripWhitespace))

#finding noise words
dtm_check <- DocumentTermMatrix(corpus)
doc_freq <- sort(colSums(as.matrix(dtm_check) > 0), decreasing = TRUE)
cat("Top terms by document frequency (out of", length(corpus), "documents), after English stopwords:\n")
print(head(doc_freq, 20))

#remove corpus-specific noise words
noise_words <- c(
  "july", "said", "tuesday", "monday", "also", "will",
  "wednesday", "thursday", "friday", "saturday", "sunday",
  "january", "february", "march", "april", "may", "june",
  "august", "september", "october", "november", "december"
)

corpus <- tm_map(corpus, removeWords, noise_words)
corpus <- suppressWarnings(tm_map(corpus, stripWhitespace))

# Question 2.2
library(topicmodels)

dtm <- DocumentTermMatrix(corpus)
dtm <- dtm[rowSums(as.matrix(dtm)) > 0,]

# fitting the LDA model
num_topics <- 5
lda_model <- LDA(dtm, k = num_topics, control = list(seed = 1234))

#probability of word appearing in topic
topic_probabilities <- as.data.frame(posterior(lda_model)$terms)

#highest-probability word per topic
terms_matrix <- terms(lda_model, 10)

#building a data frame per topic
topic_dfs <- list()
for (i in 1:num_topics) {
  topic_df <- data.frame(term = terms_matrix[, i], probability = as.numeric(topic_probabilities[i, terms_matrix[, i]]))
  topic_df <- topic_df[order(-topic_df$probability), ]
  topic_dfs[[paste("Topic", i)]] <- topic_df
}

#print summary
for (i in 1:num_topics) {
  cat(paste0("Topic ", i, ": "), paste(topic_dfs[[i]]$term, collapse = ", "), "\n")
}

#save as csv
dir.create("output", showWarnings = FALSE)
write.csv(do.call(rbind, lapply(1:num_topics, function(i) cbind(topic = i, topic_dfs[[i]]))),
          "output/topic_terms.csv", row.names = FALSE)

# Question 2.3
library(wordcloud)
library(RColorBrewer)
library(ggplot2)

dir.create("wordclouds", showWarnings = FALSE)
dir.create("barplots", showWarnings = FALSE)

#2 different visuals
for (i in 1:num_topics) {
  topic_df <- topic_dfs[[i]]
  
#word cloud
png(paste0("wordclouds/topic_", i, "_wordcloud.png"), width = 900, height = 700, res = 150)
layout(matrix(c(1, 2), nrow = 2), heights = c(1, 6))
par(mar = rep(0, 4))
plot.new()
text(0.5, 0.5, paste("Word Cloud for Topic", i), cex = 1.3, font = 2)
wordcloud(
  words = topic_df$term, freq = round(topic_df$probability * 10000),
  min.freq = 1, max.words = 30, random.order = FALSE,
  rot.per = 0.35, colors = brewer.pal(8, "Dark2"), scale = c(3, 0.5)
)
dev.off()
  
#bar plot
p <- ggplot(topic_df, aes(x = reorder(term, probability), y = probability)) +
  geom_bar(stat = "identity", fill = "lightskyblue") +
  coord_flip() +
  labs(title = paste("Top Terms in Topic", i), x = "Term", y = "Probability") +
  theme_minimal()
print(p)
ggsave(paste0("barplots/topic_", i, "_barplot.png"), p, width = 6, height = 4.5, dpi = 150)
cat("Topic", i, "saved:", paste0("wordclouds/topic_", i, "_wordcloud.png"), "and", paste0("barplots/topic_", i, "_barplot.png"), "\n")
}