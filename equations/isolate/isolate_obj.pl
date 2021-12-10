#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

BEGIN { push @INC, "."; }
use EQUATION;

$/=undef;
my $input;
my $variable;

if (@ARGV) {
	if (-e $ARGV[0]) { $input = <ARGV>  }
	else             { $input = $ARGV[0]}
}
elsif (not -t STDIN) { $input = <STDIN> }
else                 {exit}

($input, $variable) = split /,/, $input;
$variable =~ tr/ //d;


my $equation = EQUATION->new($input);

$equation->print_isolate($variable);








