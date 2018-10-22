all: RJwrapper.pdf muschelli.R motivation.pdf

RJwrapper.pdf: muschelli.Rmd muschelli.bib
	- Rscript -e "rmarkdown::render(\"muschelli.Rmd\")"

muschelli.R: muschelli.Rmd
	- Rscript -e "knitr::purl(\"muschelli.Rmd\")"		

motivation.pdf: motivation.Rmd
	- Rscript -e "rmarkdown::render(\"motivation.Rmd\")"

clean:
	rm -f RJwrapper.pdf muschelli.R motivation.pdf
