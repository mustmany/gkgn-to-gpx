#!/usr/bin/perl

use 5.014;
use warnings;
use utf8;

use Encode;
use Encode::Locale;
use File::Slurp;
use List::MoreUtils qw/ natatime /;
use Geo::Gpx;
use Math::Trig ':pi';

our $dir = 'gpx';
mkdir $dir if !-d $dir;

for my $file ( glob "data/*s.html" ) {
    my ($fname) = $file =~ m# ^ (?: .*/ )?  (.*?) s\.html#xms;

    say STDERR "$file -> $fname.gpx";
    say ".read";
    
    my $data = decode 'utf8', read_file $file;

    $data =~ s/& (?: \#160 | nbsp ) ; / /gxms;
    $data =~ s#<br/>#<br>#gxms;

    say ".split";
    my @items = $data =~ m/
        (?<= \n )
        (\d{1,5}) (?: \s*<br>\s* | \s+ )    # num
        (?: \d{7} ) \s*<br>\s*              # code
        ( .{50,2000}? )                     # data
        (?= \n
          (?:
            <b>                                     # new region (with counter reset)
            | (??{ $1+1 }) (?: \s*<br>\s* | \s+ )   # num+1
            | Стр\. \s+ \d                          # page break
          )
        )
    /gxms;

    say ".parse";
    my %point;

    my $num = 0;
    my $it = natatime 2, @items;
    while ( my ($cnum, $item) = $it->() ) {
        my ($head, $latlon, $desc) = $item =~ m/ (.*?) (\d+ ° .+? [ВЗ]\.Д\.) (.*) /xms;
        if ( !$latlon ) {
            warn "No coords for record $cnum";
            next;
        }

        my ($name, $type, $area) = split /\s*<br>\s*/xms, $head;

#        say STDERR "Counter reset $num -> $cnum" if $cnum < $num;
        warn "Records ${\($num+1)}..${\($cnum-1)} missed!"  if $cnum > $num+1;
        $num = $cnum;

        my ($latd, $latm, $lond, $lonm) = $latlon =~ m/(-?\d+)/gxms;

        $desc =~ s#(?:\s|<br>)+# #gxms;
        $desc =~ s#\w-\d+-\d+\s*##gxms;

        my $key = sprintf "%03d-%02d,%03d-%02d", $latd, $latm, $lond, $lonm;
        push @{ $point{$key} }, {
            lat     => $latd + $latm/60, # + (rand()-0.5)*0.005,
            lon     => $lond + $lonm/60,
            name    => "$name ($type)",
            desc    => $desc,
        };
    }


    my $gpx = Geo::Gpx->new();
    for my $key ( sort keys %point ) {
        my @points = sort { $a->{name} cmp $b->{name} }  @{ $point{$key} };

        if ( @points == 1 ) {
            $gpx->add_waypoint( shift @points );
        }
        else {
            my $ang = pi2 / @points;
            my $r = 0.001 / 2 / sin($ang/2);
            for my $i ( 0 .. $#points ) {
                my $point = $points[$i];
                $point->{lon} += $r * sin ( $i * $ang ) / cos( $point->{lat} * pi / 180 );
                $point->{lat} += $r * cos ( $i * $ang );
                $gpx->add_waypoint( $point );
            }
        }

    }

    
    my $xml = $gpx->xml();
    $xml =~ s/\&\#x([\dA-F]{3});/chr(hex($1))/gexms;
    write_file "$dir/$fname.gpx", encode 'utf8', $xml;
}


