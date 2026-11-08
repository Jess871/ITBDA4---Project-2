# ITBDA4 Project 2: Big Data Analytics in R

Honours Data Science, Eduvos. Author: Jessica Bawden.

All four questions are written in R. Each question folder has its scripts, data, output and an R Markdown notebook (`.Rmd`) with its knitted `.html` file.

## Questions

1. **MapReduce keyword search**: a Hadoop Streaming job (`mapper.R`, `reducer.R`) that finds a keyword in news articles and reports the document, row and column of each match.
2. **Topic modelling**: LDA on South African news articles, shown as word clouds and bar charts.
3. **Web text mining**: scrapes a dataset description from catalog.data.gov and compares word-frequency and TF-IDF summaries.
4. **ETL to PostgreSQL**: scrapes 20 books from books.toscrape.com, cleans them into `books_clean.csv`, loads them into a `books` table and queries price against rating.

## How to run

Install these packages for each question:

| Question | Packages |
|---|---|
| 1 | Base R and Hadoop Streaming (`Rscript keyword_search.R africa`) |
| 2 | tm, topicmodels, wordcloud, RColorBrewer, ggplot2 |
| 3 | rvest, jsonlite, tm, wordcloud, ggplot2 |
| 4 | rvest, DBI, RPostgres |

Open a `.Rmd` file in RStudio and click **Knit**.

### Question 4: add your own PostgreSQL password

Question 4 needs a local PostgreSQL server. My password is not included, so you have to use your own. Before you knit, run this in the R console and replace `your_password` with your PostgreSQL password:

```r
Sys.setenv(PG_PASSWORD = "your_password")
```

## Data and report

- Raw datasets: `ITBDA4-14 Project 2 Datasets-20260722/`
- Datasets I created: inside `Question 3/` and `Question 4/`
- Written report with Harvard references: `documentation/Project2_Documentation.pdf`
