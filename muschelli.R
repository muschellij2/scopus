## ----setup, include = FALSE----------------------------------------------
knitr::opts_chunk$set(
  echo = TRUE,
  message = FALSE,
  cache = TRUE,
  warning = FALSE,
  comment = ""
)

library(rscopus)

## ------------------------------------------------------------------------
library(rscopus)
key = get_api_key()

## ------------------------------------------------------------------------
key

## ------------------------------------------------------------------------
have_api_key()

## ----auth_name-----------------------------------------------------------
auth_info = process_author_name(last_name = "Muschelli", first_name = "John",
                                verbose = FALSE)
auth_info

## ------------------------------------------------------------------------
jm = author_data(last_name = "Muschelli", first_name = "John", verbose = FALSE)

## ------------------------------------------------------------------------
class(jm)
names(jm)

## ---- echo = FALSE-------------------------------------------------------
unique_title = function(x) {
  ss = sapply(strsplit(x, split = " "), 
              function(x) {
                x = x[ !tolower(x) %in% stopwords::stopwords()]
                x = x[ !x %in% c("-", "?", "--", 1:100)]
                paste(x[1:3], collapse = " ")
              })
  stopifnot(length(unique(ss)) == length(unique(x)))
  ss
}

## ------------------------------------------------------------------------
jm$df$short_title = unique_title(jm$df$`dc:title`)
head(jm$df[, c("dc:identifier", "short_title", "citedby-count")])

## ------------------------------------------------------------------------
names(jm$full_data)

## ------------------------------------------------------------------------
head(jm$full_data$author[, c("authid", "authname", "surname", "afid.$", "entry_number")])

## ------------------------------------------------------------------------
head(jm$full_data$affiliation[, c("afid", "affiliation-country", "entry_number",  "affilname")])

## ------------------------------------------------------------------------
library(dplyr)
au_id = unique(jm$df$au_id) 
co_authors = jm$full_data$author %>% 
  filter(!authid %in% au_id)
co_authors = co_authors %>% 
  add_count(authid) %>%
  select(n, authid, authname, surname) %>% 
  distinct() %>% arrange(-n)
head(co_authors)

## ----retrieval-----------------------------------------------------------
author_info = author_retrieval(last_name = "Muschelli", first_name = "J")
names(author_info$content)
class(author_info$content$`author-retrieval-response`)

## ------------------------------------------------------------------------
gen_entries_to_df(author_info$content$`author-retrieval-response`)$df

## ------------------------------------------------------------------------
h_data = jm$df %>% 
  mutate(citations = as.numeric(`citedby-count`)) %>% 
  arrange(-citations) %>% 
  mutate(n_papers = 1:n())
head(h_data[, c("short_title", "citations", "n_papers")])
h_index = max(which(h_data$citations >= h_data$n_papers))
cat(paste0("Calculated h-index is ", h_index))

## ---- fig.width=6, fig.height=4, fig.cap = paste0("Calculating an h-index.  Here we plot the number of papers versus the number of citations for that paper.  This plot is the basis for the h-index.  The X=Y line is displayed in black and the red line is where the curve passes the X=Y line, which is the h-index, a value of ", h_index, ".")----
library(ggplot2)
h_data %>% 
  ggplot(aes(x = n_papers, y = citations)) + 
  geom_point() + geom_abline(slope = 1, intercept = 0) + 
  geom_hline(yintercept = h_index, color = "red")

## ------------------------------------------------------------------------
h_data = h_data %>% mutate(sum_citations = cumsum(citations))
g_index = max(which(h_data$sum_citations >= h_data$n_papers^2))
cat(paste0("Calculated g-index is ", g_index))

## ----ssmith_info2--------------------------------------------------------
last_name = "West"
first_name = "M"
auth_info_list = get_complete_author_info(last_name = last_name, first_name = first_name)
class(auth_info_list)
names(auth_info_list)

## ------------------------------------------------------------------------
coerced = gen_entries_to_df(auth_info_list$content$`search-results`$entry)
names(coerced)
head(coerced$df[, c("dc:identifier",  "preferred-name.surname",
                    "preferred-name.given-name", "affiliation-current.affiliation-name" )])

## ------------------------------------------------------------------------
auth_info_df = get_author_info(last_name = last_name, 
                              first_name = first_name)
head(auth_info_df)

## ------------------------------------------------------------------------
spec_affil = get_author_info(
  last_name = last_name, 
  first_name = first_name,
  affil_id = 60006183)
spec_affil

## ------------------------------------------------------------------------
all_author_info = complete_multi_author_info(au_id = auth_info_df$au_id)
names(all_author_info)

## ------------------------------------------------------------------------
processed = process_complete_multi_author_info(all_author_info)
head(names(processed))

## ------------------------------------------------------------------------
names(processed$`35480328200`)

## ------------------------------------------------------------------------
head(processed$`35480328200`$affiliation_history[, c("ip-doc.afdispname", "ip-doc.id", "ip-doc.type")], 3)

## ------------------------------------------------------------------------
journals = purrr:::map_df(processed, `$`, "journals", .id = "au_id")
head(journals)

## ------------------------------------------------------------------------
sc_id = jm$df$`dc:identifier`[1]
cit_try = citation_retrieval(scopus_id = sc_id)
httr::status_code(cit_try$get_statement)
cit_try$content

## ------------------------------------------------------------------------
file = system.file("extdata", "CTOExport.csv", package = "rscopus")
citations_over_time = rscopus::read_cto(file)
names(citations_over_time)

## ------------------------------------------------------------------------
yr_cols = citations_over_time$year_columns
citations_over_time = citations_over_time$data
citations_over_time = citations_over_time %>% 
  mutate(short_title = unique_title(`Document Title`))
head(citations_over_time[, c("short_title", yr_cols[1:5])])

## ------------------------------------------------------------------------
long_cite = rscopus::read_cto_long(file)
long_cite = long_cite$data %>% 
  group_by(`Document Title`, year) %>% # get the citations per year
  summarize(citations = sum(citations), # aggregate - some duplicates merged
            `Publication Year` = unique(`Publication Year`)) %>% # keep the year in data
  mutate(short_title = unique_title(`Document Title`))
long_cite = long_cite %>% arrange(-citations, year, short_title)
head(long_cite[, c("short_title", "year", "citations")])

## ---- warning=FALSE------------------------------------------------------
# get cumulative sum
csum = long_cite %>% 
  # any missing data had no citations
  mutate(citations = ifelse(is.na(citations), 0, citations)) %>% 
  arrange(`Document Title`, year) %>% # sort for cumsum
  group_by(`Document Title`) %>% 
  mutate(citations = cumsum(citations))
# remove past and future with as.integer
csum = csum %>% 
  mutate(year = as.integer(as.character(year))) %>% 
  filter(!is.na(year)) %>% # remove < 2008 and > 2018 years
  filter(year >= `Publication Year` & citations > 0) # keep only relevant data for paper
# grab last citations and top 3 papers
last_year = csum %>% 
  arrange(`Document Title`, year) %>% # sort for slice later
  group_by(`Document Title`) %>% 
  slice(n()) %>% # keep last as max citations
  ungroup %>% arrange(-citations) %>% 
  head(3)  # get top 3
g = ggplot(csum, 
           aes(x = year, y = citations, color = short_title  )) +
  xlim(c(2010, 2018)) + geom_line() + 
  # label the titles numbers for top 3
  geom_text(data = last_year, size = 3, aes(label = short_title), 
            nudge_x = -1, nudge_y = 5)
# don't want label for document title - too many entries
g + guides(color = FALSE) + theme(text = element_text(size = 20))

## ------------------------------------------------------------------------
jhu_info = get_affiliation_info(affil_name = "Johns Hopkins")
head(jhu_info[, c("affil_id", "affil_name")])

## ------------------------------------------------------------------------
sc_id = jm$df$`dc:identifier`[1]
# retrieve abstract 
abstract = abstract_retrieval(id = sc_id, identifier = "scopus_id")

## ------------------------------------------------------------------------
sc_info = abstract$content$`abstracts-retrieval-response`
substr(sc_info$coredata$`dc:description`, 1, 76)

## ------------------------------------------------------------------------
sc_df = purrr::map_df(sc_info$authors[[1]],
  as.data.frame, stringsAsFactors = FALSE, make.names = FALSE)
head(sc_df[, c("ce.given.name", "ce.initials", "X.auid")])

## ------------------------------------------------------------------------
paper_author_info = jm$full_data$author
head(paper_author_info[paper_author_info$entry_number == 1, c("authid", "authname", "surname")])

## ------------------------------------------------------------------------
objects = object_retrieval("S1053811915002700", identifier = "pii", verbose = FALSE)
obj_df = process_object_retrieval(objects)
head(obj_df[, c("type", "url", "mime_type")])

## ------------------------------------------------------------------------
obj_df = obj_df[ grepl("image/jpeg", obj_df$mime_type),]
obj_df = obj_df[ obj_df$type %in% "IMAGE-HIGH-RES",]
object = download_object(obj_df$url[1])
object$outfile

## ---- include = FALSE----------------------------------------------------
using_doi = abstract_retrieval(id = "10.1016/j.neuroimage.2015.03.074", identifier = "doi")

## ---- echo = TRUE--------------------------------------------------------
unique_title = function(x) {
  ss = sapply(strsplit(x, split = " "), 
              function(x) {
                x = x[ !tolower(x) %in% stopwords::stopwords()]
                x = x[ !x %in% c("-", "?", "--", 1:100)]
                paste(x[1:3], collapse = " ")
              })
  stopifnot(length(unique(ss)) == length(unique(x)))
  ss
}

