# Question 3.1
#import libraries
library(rvest)
library(jsonlite)


#save file to
setwd("C:/Users/jessb/OneDrive/Desktop/University/University/CTI/Honours/Semester 2/ITBDA4/Assignment/Question 3")

#page being scraped
url <- "https://catalog.data.gov/dataset/motor-vehicle-collisions-crashes"

page <- read_html(url)

ld_json_text <- page %>% html_element("script[type='application/ld+json']") %>% html_text
dataset <- fromJSON(ld_json_text)

#Page title
title_text <- dataset$name

#print title
cat("Title:", title_text, "\n")

#fetching the text
description_text <- html_text2(read_html(paste0("<div>", dataset$description, "</div>")))
description_text <- gsub("\\s+", " ", description_text)
description_text <- trimws(description_text)

#building data structure
df <- data.frame(
  source_url = url,
  title = title_text,
  content = description_text,
  stringsAsFactors = FALSE
)

#print sanity check
cat("Scraped", nchar(df$content), "characters,",
    length(strsplit(df$content, "\\s+")[[1]]), "words, from:", url, "\n")

#save raw scraped data
write.csv(df, "scraped_raw.csv", row.names = FALSE)

#Question 3.2
library(tm)

raw_text <- df$content

#clean text
clean_text <- gsub("\\s+"," ", raw_text)
clean_text <- trimws(clean_text)

#removing text that is irrelevent
boilerplate_patterns <- c(
  "(?i)skip to main content",
  "(?i)show more\\b", "(?i)show less\\b",
  "(?i)back to the top",
  "(?i)this site uses cookies[^.]*\\.?"
)
for (pat in boilerplate_patterns) {
  clean_text <- gsub(pat, " ", clean_text, perl = TRUE)
}
clean_text <- trimws(gsub("\\s+", " ", clean_text))

cat("\nAfter denoising:", nchar(clean_text), "characters,",
    length(strsplit(clean_text, "\\s+")[[1]]), "words\n")

#split denoised text into sentences
split_sentences <- function(text) {
  sentences <- unlist(strsplit(text, "(?<=[.!?])\\s+(?=[A-Z])", perl = TRUE))
  sentences <- trimws(sentences)
  sentences[nchar(sentences) > 0]
}
sentences <- split_sentences(clean_text)
cat("Split into", length(sentences), "sentences\n")


#scoring words by importance
corpus <- Corpus(VectorSource(sentences))

corpus <- suppressWarnings(tm_map(corpus, content_transformer(function(x)
  gsub("\\b[a-z0-9][a-z0-9.-]*\\.(com|gov|org|net|us|co)\\b", " ", x, ignore.case = TRUE)
)))

corpus <- suppressWarnings(tm_map(corpus, content_transformer(tolower)))
corpus <- suppressWarnings(tm_map(corpus, removeNumbers))
corpus <- suppressWarnings(tm_map(corpus, removePunctuation))
corpus <- suppressWarnings(tm_map(corpus, removeWords, stopwords("english")))
corpus <- suppressWarnings(tm_map(corpus, stripWhitespace))

#save cleaned sentences
write.csv(data.frame(sentence_id = seq_along(sentences), sentence = sentences),
          "sentences_clean.csv", row.names = FALSE)

#Question 3.3
library(wordcloud)
library(RColorBrewer)
library(ggplot2)

n_summary_sentences <- 3

#technique 1: word frequency scoring
dtm_words <- DocumentTermMatrix(corpus)
word_freq <- colSums(as.matrix(dtm_words))
word_freq_norm <- word_freq / max(word_freq)

score_by_frequency <- function(sentence_terms) {
  terms_present <- sentence_terms[sentence_terms %in% names(word_freq_norm)]
  if (length(terms_present) == 0) return(0)
mean(word_freq_norm[terms_present])
}

sentence_terms_list <- lapply(corpus, function(doc) {
  strsplit(as.character(doc), "\\s+")[[1]]
})
freq_scores <- vapply(sentence_terms_list, score_by_frequency, numeric(1))

#technique 2: TF-IDF
dtm_tfidf <- weightTfIdf(dtm_words)
tfidf_matrix <- as.matrix(dtm_tfidf)
tfidf_scores <- rowSums(tfidf_matrix)

#build summaries
top_freq_idx <- order(-freq_scores)[1:n_summary_sentences]
top_tfidf_idx <- order(-tfidf_scores)[1:n_summary_sentences]

#sort sentences
summary_wordfreq <- sentences[sort(top_freq_idx)]
summary_tfidf <- sentences[sort(top_tfidf_idx)]

cat("\nSummary (technique 1: word frequency)\n")
cat(paste(summary_wordfreq, collapse = " "), "\n")

cat("\nSummary (technique 2: TF-IDF)\n")
cat(paste(summary_tfidf, collapse = " "), "\n")

cat("Sentences chosen by both techniques:", length(intersect(top_freq_idx, top_tfidf_idx)),
    "out of", n_summary_sentences, "\n")

orig_words <- sum(lengths(strsplit(sentences, "\\s+")))
compression <- function(s) round(sum(lengths(strsplit(s, "\\s+"))) / orig_words * 100, 1)

cat("Compression: word frequency", compression(summary_wordfreq), "%, TF-IDF",
    compression(summary_tfidf), "% of", orig_words, "words\n")


#save summaries as csv
write.csv(data.frame(
          sentence_id = seq_along(sentences),
          sentence = sentences,
          wordfreq_score = round(freq_scores, 4),
          tfidf_score = round(tfidf_scores, 4),
          chosen_by_wordfreq = seq_along(sentences) %in% top_freq_idx,
          chosen_by_tfidf = seq_along(sentences) %in% top_tfidf_idx
          ), "sentence_scores.csv", row.names = FALSE)

dir.create("plots", showWarnings = FALSE)


#visualisation 1
draw_cloud <- function() {
  set.seed(1234)
  layout(matrix(c(1, 2), nrow = 2), heights = c(1, 6))
  par(mar = rep(0, 4))
  plot.new()
  text(0.5, 0.5, "Most Frequent Terms in the Collision Dataset Description", font = 2)
  wordcloud(
    words = names(word_freq), freq = word_freq,
    min.freq = 1, max.words = 40, random.order = FALSE,
    rot.per = 0.35, colors = brewer.pal(8, "Dark2")
  )
  layout(1)
}

draw_cloud()

png("plots/Wordcloud.png", width = 900, height = 700, res = 150)
draw_cloud()
dev.off()

#visualisation 2
scores_long <- data.frame(
  sentence_id = factor(rep(seq_along(sentences), 2)),
  technique = rep(c("Word Frequency", "TF-IDF"), each = length(sentences)),
  score = c(freq_scores / max(freq_scores), tfidf_scores / max(tfidf_scores)),
  chosen = c(seq_along(sentences) %in% top_freq_idx,
             seq_along(sentences) %in% top_tfidf_idx)
)

p <- ggplot(scores_long, aes(x = sentence_id, y = score, fill = technique, alpha = chosen)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_alpha_manual(values = c(0.35, 1), labels = c("Not selected", "Selected"), name = "") +
  labs(title = "Sentence Importance Score by Summarisation Technique",
       x = "Sentence Number", y = "Score (normalised 0-1)", fill = "Technique") +
  theme_minimal()
print(p)
ggsave("plots/Barplot.png", p, width = 8, height = 4.5, dpi = 150)