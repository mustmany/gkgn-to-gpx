#!/usr/bin/perl

use 5.014;
use warnings;
use utf8;

use Encode;
use Encode::Locale;

my $ENC = 'UTF-8';  # KOI8-R

for my $file ( glob("data/*.pdf") ) {
    say encode console_out => decode locale_fs => $file;

    # propagate modification time: take file time as defaulf...
    my $mtime = [ stat $file ]->[9];

    # ... but try to det pdf time
    eval {
        require PDF::API2;
        my %info = PDF::API2->open($file)->info();
        my $pdftime = $info{CreationDate}  or die;
        say "PDF time: $pdftime";

        # D:20130121161344+03'00'
        require POSIX;
        my ($Y,$M,$D,$h,$m,$s,$z) = $pdftime =~ / (\d{4}) (\d{2}) (\d{2}) (\d{2}) (\d{2}) (\d{2}) \+ (\d{2}) /xms;
        my $time = POSIX::mktime($s,$m,$h,$D,$M-1,$Y-1900)  or die;
        $mtime = $time;
    };

    `pdftohtml "$file" -enc $ENC`;

    my $html = $file =~ s/\.pdf$/s.html/ixmsr;
    utime $mtime, $mtime, $html;
}

unlink for grep { ! /s\.html/ } glob 'data/*.html';


