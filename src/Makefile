# Makefile for compiling SICP in multiple language editions.
# (c) 2014 Andres Raba, GNU GPL v.3.
# Extended for multilingual support.
#
# Usage:
#   make                — build English epub + pdf
#   make LANG=vi        — build Vietnamese epub + pdf
#   make LANG=vi html   — build Vietnamese HTML only
#   make html-langs     — build HTML for all languages in languages.conf
#   make all-langs      — build epub+pdf for all languages

LANG  ?= en_US
DIR    = $(LANG)/
SRC    = ../books/$(LANG)/sicp.texi
GOAL   = ../sicp-$(LANG).epub
PDF    = pdf/sicp-$(LANG).pdf
NEXUS  = $(DIR)index.xhtml
META   = content.opf toc.xhtml
HTML   = $(DIR)*.xhtml
FIG    = $(DIR)fig/*/*.svg
CSS    = $(DIR)css/*.css
FONT   = $(DIR)css/fonts/*
JS     = $(DIR)js/*.js
CONV   = texi2any lib/Texinfo/Convert/HTML.pm
MATH   = get-math.js put-math.js mathcell.xhtml
HIGHL  = en_US/js/highlight/
PRETTY = $(HIGHL)prettify.js $(HIGHL)lang-lisp.js batch-prettify.js
COVER  = index.in.xhtml $(DIR)fig/coverpage.std.svg $(DIR)fig/bookwheel.jpg
THUMB  = $(DIR)fig/cover.png
SHELL  = /bin/bash

# Read supported languages from languages.conf (skip comments and blank lines)
LANGUAGES ?= $(shell grep -v '^\s*#' ../languages.conf 2>/dev/null | grep -v '^\s*$$' | tr '\n' ' ')

JQ = <script src=\"js/jquery.min.js\" type=\"text/javascript\"></script>
FT = <script src=\"js/footnotes.js\" type=\"text/javascript\"></script>
BR = <script src=\"js/browsertest.js\" type=\"text/javascript\"></script>

GITHUB = <a href=\"https://github.com/tamnd/sicp\"><img style=\"position: absolute; top: 0; right: 0; border: 0; width: 149px; height: 149px; z-index: 10; opacity: 0.5;\" src=\"http://aral.github.com/fork-me-on-github-retina-ribbons/right-red\@2x.png\" alt=\"Fork me on GitHub\" /></a>

# ============================================================
# Primary targets
# ============================================================

all: $(GOAL) $(PDF)
	@if ! grep -m 1 -l 'browsertest' $(NEXUS); then \
	  for file in $(HTML); do \
	    perl -0p -i.bak -e \
	      "s{\s*</head>}{\n\n$(JQ)\n$(FT)\n$(BR)\n</head>}" $$file; \
	  done; \
	  rm $(DIR)*.bak; \
	fi; \
	perl -0p -i.bak -e \
	  "s{<!-- Fork me banner -->}{$(GITHUB)}" index.xhtml; \
	rm *.bak

html: $(NEXUS)

epub: $(GOAL)

pdf: $(PDF)

# ============================================================
# HTML build
# ============================================================

# For non-en_US, ensure shared assets (css/js/fig) exist in target dir first
ifneq ($(LANG),en_US)
$(NEXUS): copy-assets
endif

.PHONY: copy-assets
copy-assets:
ifneq ($(LANG),en_US)
	@mkdir -p $(DIR)
	@[ -d $(DIR)css ] || cp -r en_US/css $(DIR)
	@[ -d $(DIR)js  ] || cp -r en_US/js  $(DIR)
	@[ -d $(DIR)fig ] || cp -r en_US/fig $(DIR)
	@if [ -d lang/$(LANG)/css ]; then cp -r lang/$(LANG)/css/. $(DIR)css/; fi
endif

$(NEXUS): $(SRC) $(CONV) $(MATH)
	@echo "Converting Texinfo to HTML (LANG=$(LANG))..."
	@# Texinfo 5.2 does not resolve nested @include paths relative to the
	@# including file. We stage a copy of the book and rewrite every
	@# "@include RELPATH" to be relative to the book root, then run
	@# texi2any from that staging root.
	@# We also overlay our modified Texinfo::Convert::HTML.pm (produces
	@# .xhtml output) onto the system install — @INC ordering in
	@# texi2any's BEGIN block would otherwise pick up the stock file.
	@SYS_HTML=/usr/local/share/texinfo/Texinfo/Convert/HTML.pm; \
	 if [ -w $$SYS_HTML ] && ! cmp -s lib/Texinfo/Convert/HTML.pm $$SYS_HTML; then \
	   cp lib/Texinfo/Convert/HTML.pm $$SYS_HTML; \
	 fi
	@SRC_ABS=$$(cd $(dir $(SRC)) && pwd); \
	 STAGE=$$(pwd)/build-$(LANG); \
	 OUT_ABS=$$(pwd)/$(DIR); \
	 rm -rf $$STAGE && mkdir -p $$OUT_ABS; \
	 ./stage-texi.pl $$SRC_ABS $$STAGE; \
	 ln -s ../en_US/fig $$STAGE/fig; \
	 (cd $$STAGE && texi2any \
	   --no-warn --html --split=section --no-headers --iftex \
	   --force --output $$OUT_ABS $(notdir $(SRC))) || true
	@rm -rf build-$(LANG)
	@test -f $(NEXUS) || { echo "texi2any failed to produce $(NEXUS)"; exit 1; }
	@grep -lZ 'This file redirects' $(HTML) | xargs -0 rm -f -- || true
	@echo "Replacing LaTeX with MathML..."
	@./get-math.js db-$(LANG).json $(HTML)
	@./put-math.js db-$(LANG).json $(HTML)
	@echo "Syntax highlighting Scheme code..."
	@./batch-prettify.js $(HTML)
	@# Normalize output to valid XHTML:
	@#   * prepend <?xml?> declaration
	@#   * self-close void elements (link/meta/br/hr/img/...)
	@#   * replace named &nbsp; (undefined in XHTML) with numeric &#160;
	@for file in $(HTML); do \
	  perl -0p -i -e 's/^<!DOC/<?xml version="1.0" encoding="utf-8"?>\n<!DOC/; s{&nbsp;}{&#160;}g; s{(<(?:link|meta|br|hr|img|input|area|base|col|embed|param|source|track|wbr)\b[^>]*?)(?<!/)>}{$$1 />}g;' $$file; \
	done
	@perl -0p -i -e \
	  's{\.\./dir/index\.xhtml}{../index.xhtml}g' $(NEXUS)
ifneq ($(LANG),en_US)
	@# texi2any 5.2 double-encodes UTF-8 in <title> and <meta>: source
	@# bytes are interpreted as Latin-1 then re-encoded as UTF-8, giving
	@# mojibake like "Cáº¥u" for "Cấu". Body text is fine. Round-trip
	@# decode-utf8 / encode-latin1 recovers the original UTF-8 bytes.
	@# Also link lang.css for language-specific font overrides.
	@for file in $(HTML); do \
	  perl -CSD -0p -i -e 'use Encode; \
	    sub fixenc { my $$s = shift; $$s =~ s/&(?:nbsp|\#160);/\xa0/g; \
	      $$s =~ s/([\x80-\xff]+)/Encode::decode("UTF-8", Encode::encode("latin-1", $$1), Encode::FB_DEFAULT)/ge; \
	      $$s } \
	    s{(<title>)([^<]+)(</title>)}{$$1.fixenc($$2).$$3}ge; \
	    s{(<meta name="(?:description|keywords)" content=")([^"]+)(")}{$$1.fixenc($$2).$$3}ge; \
	    s{(<link href="css/prettify\.css"[^>]*?/>)}{$$1 . "\n" . q(<link href="css/lang.css" rel="stylesheet" type="text/css" />)}ge;' \
	    $$file; \
	done
endif

# ============================================================
# EPUB build
# ============================================================

$(META): $(NEXUS) create_metafiles.rb
	@echo "Building ePub3 metadata (LANG=$(LANG))..."
	@for file in $(HTML); do \
	  sed -i.bak "s/xmlns:xml[^ ]\+[ ]//" $$file; \
	done; \
	rm $(DIR)*.bak
	@LANG_DIR=$(DIR) ./create_metafiles.rb

$(THUMB): $(COVER)
	@inkscape --export-background="#fbfbfb" --export-area-page \
	  --export-filename=$(THUMB) $(DIR)fig/coverpage.std.svg > /dev/null 2>&1

$(GOAL): $(META) $(THUMB) $(FIG) $(CSS) $(FONT) mimetype META-INF/* LICENSE
	@if [ -f $(GOAL) ]; then rm $(GOAL); fi
	@if grep -q -m 1 'browsertest' $(NEXUS); then \
	  for file in $(HTML); do \
	    perl -0p -i.bak -e \
	      "s{\n$(JQ)\n$(FT)\n$(BR)\n}{}" $$file; \
	  done; \
	  rm $(DIR)*.bak; \
	fi
	@zip -0Xq $(GOAL) mimetype
	@cp index.in.xhtml index.xhtml
	@zip -Xr9Dq $(GOAL) $(META) $(HTML) META-INF/* LICENSE \
	  index.xhtml $(DIR)css/* $(DIR)fig/*
	@echo "Built $(GOAL)."

# ============================================================
# PDF (delegates to src/pdf/Makefile)
# ============================================================

$(PDF):
	$(MAKE) -C pdf LANG=$(LANG)

# ============================================================
# Multi-language convenience targets
# ============================================================

.PHONY: html-langs epub-langs pdf-langs all-langs

html-langs:
	@for lang in $(LANGUAGES); do \
	  echo "=== HTML: $$lang ==="; \
	  $(MAKE) LANG=$$lang html; \
	done

epub-langs:
	@for lang in $(LANGUAGES); do \
	  echo "=== EPUB: $$lang ==="; \
	  $(MAKE) LANG=$$lang epub; \
	done

pdf-langs:
	@for lang in $(LANGUAGES); do \
	  echo "=== PDF: $$lang ==="; \
	  $(MAKE) LANG=$$lang pdf; \
	done

all-langs:
	@for lang in $(LANGUAGES); do \
	  echo "=== Building all formats: $$lang ==="; \
	  $(MAKE) LANG=$$lang all; \
	done

.PHONY: all epub html pdf
