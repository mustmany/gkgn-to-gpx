#!/usr/bin/perl

use 5.014;
use warnings;
use utf8;

use URI::Escape;
use Encode;
use Encode::Locale;

my $base_url = 'https://www.rosreestr.ru';
my $list_url = "$base_url/wps/portal/cc_ib_data_catalog_place_names?param_infoblock_document_path=infoblock-root/cc_ib_data_catalog_place_names/index.htm";

my $dir = "data";
mkdir $dir if !-d $dir;

my $data = decode utf8 => `curl -k "$list_url"`;
my @links = $data =~ m# " / ([^"]+ \. (?: zip | arj | rar | 7z | pdf ) ) " #igxms;

for my $link ( map { uri_unescape $_ } @links ) {
    my ($file) = $link =~ m# / ([^/]+) $ #xms;
    my $local_fn = encode locale_fs => "$dir/$file";
    say encode console_out => $file;

    if ( !-s $local_fn ) {
        my $url = "$base_url/$link";
        `wget "$url" --no-check-certificate -O "$local_fn"`;
    }


}

