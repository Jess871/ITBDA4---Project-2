# ITBDA4 Project 2

Honours Data Science, Eduvos. 

This repository has my work for ITBDA4 Project 2. There are four questions, all done in R. Each question has its own folder.

## Folder layout

```
ITBDA4---Project-2/
  README.md
  documentation/
    Project2_Documentation.pdf      <- written report
  ITBDA4-14 Project 2 Datasets-20260722/   <- raw datasets supplied
  Question 1/
    explore_corpus.R                <- explores the articles first
    keyword_search.R                <- runs the Hadoop job
    mapper.R, reducer.R             <- MapReduce code
    Input/                          <- article files searched
    output/                         <- search results
  Question 2/
    Question2.R
    output/                         <- topic results
    wordclouds/, barplots/          <- topic charts
  Question 3/
    Question3.R
    scraped_raw.csv                 <- text scraped from the web page
    sentences_clean.csv             <- cleaned sentences
    sentence_scores.csv             <- sentence scores
    plots/                          <- word cloud and bar chart
  Question 4/
    Question4.R
    books_clean.csv                 <- cleaned book data
```


## Report

The written report for all four questions, with the results explained and the Harvard references, is in `documentation/Project2_Documentation.pdf`.
