all: RJwrapper.pdf index.R motivation.pdf

RJwrapper.pdf: index.Rmd index.tex index.bib
	- Rscript -e "rmarkdown::render(\"index.Rmd\")"

index.R: index.Rmd
	- Rscript -e "knitr::purl(\"index.Rmd\")"		

motivation.pdf: motivation.Rmd
	- Rscript -e "rmarkdown::render(\"motivation.Rmd\")"

clean:
	rm -f RJwrapper.pdf index.R
