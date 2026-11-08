# Question 4.1

# save here
setwd("C:/Users/jessb/OneDrive/Desktop/University/University/CTI/Honours/Semester 2/ITBDA4/Assignment/Question 4")

#import libraries
library(rvest)

#web scraping
url <- "https://books.toscrape.com/"
page <- read_html(url)

book_nodes <- page %>% html_elements("article.product_pod")
cat("Found", length(book_nodes), "books on this page")

#number of books on page
length(book_nodes)

#title of books
title <- book_nodes %>% html_element("h3 a") %>% html_attr("title")

#price
price_raw <- book_nodes %>% html_element(".price_color") %>% html_text2()

#rating
rating_class <- book_nodes %>% html_element("p.star-rating") %>% html_attr("class")
rating_word <- gsub("star-rating\\s+", "", rating_class)

#availability
availability_raw <- book_nodes %>% html_element(".instock.availability") %>% html_text()

#building r structure
df <- data.frame(
  title = title,
  price_raw = price_raw,
  rating_word = rating_word,
  availability_raw = availability_raw,
  stringsAsFactors = FALSE

)

cat("Scraped", nrow(df), "records")
print(head(df, 3))


# Question 4.2

#clean price
df$price <- as.numeric(gsub("[^0-9.]", "", df$price_raw))

#clean the rating word
rating_lookup <- c(One = 1, Two = 2, Three = 3, Four = 4, Five = 5)
df$rating <- rating_lookup[df$rating_word]

#denoise availability
df$availability <- trimws(gsub("\\s+", " ", df$availability_raw))


#Test for missing values
colSums(is.na(df))

#keep only final and values
books_clean <- df[, c("title", "price", "rating", "availability")]
colnames(books_clean) <- c("Title", "Price", "Rating", "Availability")

cat("Cleaned dataset:")
print(head(books_clean))
str(books_clean)

#export cleaned dataset
write.csv(books_clean, "books_clean.csv", row.names = FALSE)

#print clean dataset
print(books_clean)

#Question 4.2
# Load into postgresql

#libraries
library(DBI)
library(RPostgres)

#setup details
con_setup <- dbConnect(
  RPostgres::Postgres(),
  dbname = "postgres",
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "2P7e2/2X]Fh" #please enter your password here
  
)

#creating books_db database
db_exists <- dbGetQuery(con_setup, "SELECT 1 FROM pg_database WHERE datname = 'books_db'")
if (nrow(db_exists) == 0) {
  dbExecute(con_setup, "CREATE DATABASE books_db")
  cat("Database 'books_db' did not exist - created it.")
} else {
  cat("Database 'books_db' already exists -using it as is")
}
dbDisconnect(con_setup)

#connection details
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "books_db",
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "2P7e2/2X]Fh"
  
)

#writing to postgresql
dbWriteTable(con, "books", books_clean, overwrite = TRUE, row.names = FALSE)

#Investigation 1: does a higher rating mean a higher price
cat("Investigation 1: average price by star rating")
investigation1 <- dbGetQuery(con, '
                            SELECT "Rating", ROUND(AVG("Price")::numeric, 2) AS avg_price, COUNT(*) AS n_books
                            FROM books
                            GROUP BY "Rating"
                            ORDER BY "Rating";
                            ')
print(investigation1)



#Investigation 2: which books are most expensive
cat("Investigation 2: top 5 most expensive books")
investigation2 <- dbGetQuery(con, '
                             SELECT "Title", "Price", "Rating"
                             FROM books
                             ORDER BY "Price" DESC
                             LIMIT 5;
                             ')
print(investigation2)

dbDisconnect(con)
cat("Complete")