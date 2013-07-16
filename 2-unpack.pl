#!/usr/bin/perl

use 5.014;
use warnings;
use utf8;

chdir 'data';

`unzip -j '*.zip'`;
`unrar e '*.rar'`;
`7z e '*.arj'`;



