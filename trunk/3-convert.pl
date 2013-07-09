#!/usr/bin/perl

use 5.014;
use warnings;
use utf8;

#for my $file ( glob("data/??_F_201.pdf"), glob("data/*\\ 3.pdf") ) {
for my $file ( glob("data/*.pdf") ) {
#    `pdftohtml "$file" -enc KOI8-R`;
    `pdftohtml "$file" -enc UTF-8`;
}
