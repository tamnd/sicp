#!/usr/bin/env perl
# Recursively inline @include directives in a Texinfo file.
# Usage: flatten-texi.pl <input.texi>
# Output goes to stdout.

use 5.012;
use warnings;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

sub flatten {
    my ($path) = @_;
    my $abs = abs_path($path) or die "Cannot resolve: $path\n";
    my $dir  = dirname($abs);
    open my $fh, '<:encoding(UTF-8)', $abs or die "Cannot open $abs: $!\n";
    while (my $line = <$fh>) {
        if ($line =~ /^\@include\s+(\S+)\s*$/) {
            flatten("$dir/$1");
        } else {
            print $line;
        }
    }
    close $fh;
}

die "Usage: $0 <input.texi>\n" unless @ARGV;
flatten($ARGV[0]);
