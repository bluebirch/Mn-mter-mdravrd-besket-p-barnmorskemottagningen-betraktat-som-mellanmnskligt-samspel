artikel.pdf: meta.yaml $(shell cat layout.md) refs.md
	pandoc -f markdown -o $@ -F ./authorea-citations-filter --bibliography bibliography/biblio-biblatex.bib --latex-engine=xelatex $+