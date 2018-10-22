all: RJwrapper.pdf index.R

RJwrapper.pdf: index.Rmd index.tex index.bib
	- Rscript -e "rmarkdown::render(\"index.Rmd\")"

index.R: index.Rmd
	- Rscript -e "knitr::purl(\"index.Rmd\")"		

clean:
	rm -f RJwrapper.pdf index.R