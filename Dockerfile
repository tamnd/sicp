FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    latexmk \
    texlive-xetex \
    texlive-latex-extra \
    texlive-fonts-extra \
    fonts-linuxlibertine \
    fonts-inconsolata \
    inkscape \
    perl \
    ruby \
    ruby-nokogiri \
    zip \
    && rm -rf /var/lib/apt/lists/*
