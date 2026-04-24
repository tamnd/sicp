# Makefile for building sicp.pdf in one or more language editions.
# Usage:
#   make              — build English PDF (sicp.pdf)
#   make LANG=vi      — build Vietnamese PDF (sicp-vi.pdf)
#
# Contributed by holomorph, 2013.
# Added to by Andres Raba, 2013-2015.
# Extended for multilingual support.

LANG ?= en_US

FIG := $(patsubst %.svg,%.pdf,$(wildcard fig/*/*.svg))
DIR := $(shell pwd)

ifeq ($(LANG),en_US)
  TEXI_SRC = sicp.texi
  TEX_OUT  = sicp.tex
  PDF_OUT  = sicp.pdf
  PREAMBLE = preamble.tex
else
  TEXI_SRC = sicp-$(LANG)-flat.texi
  TEX_OUT  = sicp-$(LANG).tex
  PDF_OUT  = sicp-$(LANG).pdf
  PREAMBLE = preamble-$(LANG).tex
endif

all: $(PDF_OUT)

$(PDF_OUT): $(TEX_OUT) exercises.tex figures.tex coverpage.pdf ${FIG}
	latexmk -pdflatex="xelatex %O %S" -pdf -dvi- -ps- $<

$(TEX_OUT): $(TEXI_SRC) $(PREAMBLE) postamble.tex texi-to-latex.pl
	SICP_PREAMBLE=$(PREAMBLE) ./texi-to-latex.pl -o $@ $<

# Flatten @include directives for non-en_US editions
sicp-$(LANG)-flat.texi: ../../books/$(LANG)/sicp.texi
	../../scripts/flatten-texi.pl $< > $@

exercises.tex figures.tex: ex-fig-ref.pl
	./ex-fig-ref.pl -e > exercises.tex; \
	./ex-fig-ref.pl -f > figures.tex

%.pdf: %.svg
	inkscape --export-area-page --export-filename=${DIR}/$@ ${DIR}/$<

clean:
	latexmk -CA
	rm -f exercises.tex figures.tex coverpage.pdf ${FIG}
	rm -f sicp-*-flat.texi

clean-all: clean
	${RM} sicp*.pdf sicp*.tex

.PHONY: all clean clean-all
