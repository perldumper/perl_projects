#!/usr/bin/perl

#use strict;
#use warnings;
use Data::Dumper;

$struct = { foo => { bar => 1 } };
$node = $struct->{foo};		# points at { bar => 1 } in $struct
$node = { bar => 2 } ;		# points at { bar => 2 } and not longer into $struct
print(Dumper($struct));		# unchanged

$struct = { foo => { bar => 1 } };
$node = \$struct->{foo};	# reference to value of { foo => ... }, currently { bar => 1 }
$$node = { bar => 2 } ;		# changes value of { foo => ... } to { bar => 2 }
print(Dumper($struct));		# changed
