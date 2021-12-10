#!/usr/bin/perl

use strict;
use warnings;


sub make_powerset { # set of all subsets of a set
	my @set = @_;
	my $set_size = @set;
	my @powerset;
	my $pow_set_size = 2 ** $set_size;
	my $counter;
	my $j;
	my @subset;
  
	# skip $counter=0 to skip empty set
	for($counter = 1; $counter < $pow_set_size; $counter++) { 
		@subset = ();
		for($j = 0; $j < $set_size; $j++) { 
			push @subset, $set[$j] if $counter & (1 << $j);
		} 
		push @powerset, [ @subset ];
	} 
	return @powerset;
} 
  
my @set = 1 .. 7;

$,="";
$\="\n";
print $_->@* foreach make_powerset @set;

