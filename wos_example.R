library(rwos)
library(webofscience)
library(dplyr)
sid <- wos_authenticate()
res <- wos_search(sid, "AU=Muschelli John")
prem_res <- wos_search(sid, "AU=Muschelli John", 
	api = "premium")
pubs <- wos_retrieve_all(res)
pubs = pubs %>% 
	mutate(ISI_LOC = sub("WOS:", "", uid))
ut = pubs$ISI_LOC
ut = sub("WOS:", "", ut)


info = ws_incites_by_ut(ut = ut, esci = "y")

df = info$content$api$rval
stopifnot(length(df) == 1)
df = df[[1]]

setdiff(pubs$ISI_LOC, df$ISI_LOC)
res_df = left_join(df, pubs)

readr::write_rds(res_df, "wos_data.rds", compress = "xz")

res_df = res_df %>% 
  mutate(TOT_CITES = as.numeric(TOT_CITES))
