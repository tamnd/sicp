# Local development image. The canonical published image lives in tamnd/sicp-docker.
# Keep this in sync with https://github.com/tamnd/sicp-docker/blob/main/Dockerfile

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    fontconfig \
    fonts-linuxlibertine \
    inkscape \
    latexmk \
    make \
    nodejs \
    perl \
    ruby \
    ruby-nokogiri \
    texinfo \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-lang-other \
    texlive-latex-extra \
    texlive-latex-recommended \
    texlive-plain-generic \
    texlive-xetex \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/share/texinfo /usr/local/share/texinfo

# Install Inconsolata LGC (OpenType) so fontspec can find it by name.
RUN curl -fsSL \
      "https://github.com/MihailJP/Inconsolata-LGC/releases/download/LGC-2.002/InconsolataLGC-OT-2.002.tar.xz" \
      -o /tmp/InconsolataLGC.tar.xz \
    && mkdir -p /tmp/inconsolata-lgc /usr/local/share/fonts/inconsolata-lgc \
    && tar -xf /tmp/InconsolataLGC.tar.xz -C /tmp/inconsolata-lgc/ \
    && find /tmp/inconsolata-lgc -name "*.otf" \
         -exec install -Dm644 {} /usr/local/share/fonts/inconsolata-lgc/ \; \
    && rm -rf /tmp/inconsolata-lgc /tmp/InconsolataLGC.tar.xz \
    && fc-cache -fv

WORKDIR /workspace

CMD ["bash"]
