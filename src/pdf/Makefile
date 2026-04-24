# Makefile for building sicp.pdf from the Texinfo source.
# Run from this directory; texi2pdf is invoked in the parent (src/)
# so that @include paths (exercises.texi, figures.texi) resolve correctly.

SRC   = ../sicp-pocket.texi
OUT   = sicp.pdf
SHELL = /bin/bash

all: $(OUT)

$(OUT):
	cd .. && texi2pdf --batch --tidy --output=pdf/$(OUT) sicp-pocket.texi

clean:
	rm -f $(OUT)

.PHONY: all clean
