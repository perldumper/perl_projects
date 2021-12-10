#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

my $dsc = [ [ [1],2 ], [3],4 ];

$\="\n";

print Dumper $dsc;

my $temp = $dsc;

$temp = [$dsc->@*];

my $copy = $temp;

$temp->[0]->[0] = $dsc->[0]->[0];

$dsc->[0]->[0] = 5;

print Dumper $dsc;
print Dumper $copy;

print $dsc->[0]->[0];


__END__
perl -le '$aref=[1,2,3]; $copy=[$aref->@*]; print $aref->@*; print $copy->@*; $ref=$copy; $ref->[0]=4; print $aref->@*; print $copy->@*'





























