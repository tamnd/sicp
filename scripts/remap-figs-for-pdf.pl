#!/usr/bin/env perl
# remap-figs-for-pdf.pl SRC_PDF_DIR < flat.texi > flat.remapped.texi
#
# Book chapter texis use HTML figure conventions (e.g. fig/chap1/Fig1.3d
# with extension .std.svg). The PDF build pipeline in src/pdf/fig/ uses
# different revision letters (Fig1.3c) and bakes figures to .pdf. This
# script rewrites @image{path/Stem,W,H,A,EXT} directives so they refer
# to figures that actually exist in SRC_PDF_DIR/fig/.
#
# Strategy: build a map per chapter directory by listing actual files,
# then for each book reference, find a file whose stem starts with the
# same FigX.Y prefix. Ambiguities prefer the alphabetically-earliest
# variant letter (matches the canonical en_US src/pdf/sicp.texi).

use strict;
use warnings;
use File::Basename qw(basename);

my $pdfdir = shift @ARGV or die "usage: $0 SRC_PDF_DIR\n";
my $figroot = "$pdfdir/fig";
die "no $figroot\n" unless -d $figroot;

my %byChapter;     # { "chap1" => { "Fig1.3" => "Fig1.3c", ... } }
my %stemsByChapter; # { "chap1" => [list of stems] }
opendir(my $rd, $figroot) or die $!;
for my $sub (readdir $rd) {
    next if $sub =~ /^\./;
    my $d = "$figroot/$sub";
    next unless -d $d;
    opendir(my $sd, $d) or next;
    my @stems;
    for my $f (readdir $sd) {
        next unless $f =~ /\.(?:pdf|svg|jpg|jpeg|png)$/i;
        my $stem = $f;
        $stem =~ s/\.(?:pdf|svg|jpg|jpeg|png)$//i;
        push @stems, $stem;
    }
    closedir $sd;
    $stemsByChapter{$sub} = [sort @stems];
    # Group by FigX.Y prefix (everything before trailing letters)
    my %byPrefix;
    for my $s (@stems) {
        my $key = $s;
        $key =~ s/[a-z]+$// if $s =~ /^Fig\d+\.\d+[a-z]+$/;
        push @{$byPrefix{$key}}, $s;
        push @{$byPrefix{$s}}, $s;  # also self-key (exact match)
    }
    for my $k (keys %byPrefix) {
        my @cands = sort @{$byPrefix{$k}};
        $byChapter{$sub}{$k} = $cands[0];
    }
}
closedir $rd;

while (my $line = <STDIN>) {
    $line =~ s{\@image\{([^,\}]+),([^,\}]*),([^,\}]*),([^,\}]*),\.([a-zA-Z\.]+)\}}{
        my ($path, $w, $h, $a, $ext) = ($1, $2, $3, $4, $5);
        my $newpath = $path;
        my $newext = ".pdf";
        if ($path =~ m|^(.*)/([^/]+)$|) {
            my ($dir, $stem) = ($1, $2);
            my $chap = basename($dir);
            my $key = $stem;
            $key =~ s/[a-z]+$// if $stem =~ /^Fig\d+\.\d+[a-z]+$/;
            my $mapped = $byChapter{$chap}{$key} || $byChapter{$chap}{$stem};
            if (!$mapped && $stemsByChapter{$chap}) {
                # fallback: longest available stem that is a prefix of $stem,
                # or shortest stem of which $key is a prefix.
                for my $s (@{$stemsByChapter{$chap}}) {
                    if (index($s, $key) == 0) { $mapped = $s; last; }
                }
            }
            $newpath = "$dir/$mapped" if $mapped;
            # If the resolved file is .jpg/.png/.jpeg, preserve that ext;
            # otherwise default to .pdf (built from .svg by inkscape rule).
            if ($byChapter{$chap}) {
                for my $e (qw(jpg jpeg png)) {
                    if (-e "$figroot/$chap/" . basename($newpath) . ".$e") {
                        $newext = ".$e";
                        last;
                    }
                }
            }
        }
        "\@image{$newpath,$w,$h,$a,$newext}";
    }gex;
    print $line;
}
