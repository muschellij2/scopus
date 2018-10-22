all: RJwrapper.pdf muschelli.R motivation.pdf muschelli.zip

RJwrapper.pdf: muschelli.Rmd muschelli.bib
	- Rscript -e "rmarkdown::render(\"muschelli.Rmd\", clean = FALSE)"
	- rm -f muschelli.knit.md muschelli.utf8.md
	- rm -f RJwrapper.log
	- rm -f RJwrapper.aux
	- rm -f RJwrapper.bbl
	- rm -f RJwrapper.out
	- rm -f RJwrapper.blg
	- rm -f RJwrapper.brf

muschelli.zip: RJwrapper.pdf motivation.pdf muschelli.R muschelli.Rmd muschelli.bib muschelli.tex muschelli_files/*
	- rm -f muschelli.zip
	- zip -r muschelli.zip RJournal.sty RJwrapper.pdf RJwrapper.tex Rlogo.png motivation.* muschelli.R muschelli.Rmd muschelli.bib muschelli.tex muschelli_files 

muschelli.R: muschelli.Rmd
	- Rscript -e "knitr::purl(\"muschelli.Rmd\")"		

motivation.pdf: motivation.Rmd
	- Rscript -e "rmarkdown::render(\"motivation.Rmd\")"

clean:
	rm -f RJwrapper.pdf muschelli.R motivation.pdf
