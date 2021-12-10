#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use lib ".";
use menu;
use dd;

my @lines = qx{ cd; ls };

# say @lines;

my $menu = menu->new(@lines);

dd $menu;


__END__

