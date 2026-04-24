FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    make \
    curl \
    xz-utils \
    latexmk \
    texlive-xetex \
    texlive-latex-extra \
    texlive-fonts-extra \
    fonts-linuxlibertine \
    inkscape \
    perl \
    ruby \
    ruby-nokogiri \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Install Inconsolata LGC (OpenType) so fontspec can find it by name
RUN curl -fsSL \
      "https://github.com/MihailJP/Inconsolata-LGC/releases/download/LGC-2.002/InconsolataLGC-OT-2.002.tar.xz" \
      -o /tmp/InconsolataLGC.tar.xz \
    && mkdir -p /tmp/inconsolata-lgc /usr/local/share/fonts/inconsolata-lgc \
    && tar -xf /tmp/InconsolataLGC.tar.xz -C /tmp/inconsolata-lgc/ \
    && find /tmp/inconsolata-lgc -name "*.otf" \
         -exec install -Dm644 {} /usr/local/share/fonts/inconsolata-lgc/ \; \
    && rm -rf /tmp/inconsolata-lgc /tmp/InconsolataLGC.tar.xz \
    && fc-cache -fv
