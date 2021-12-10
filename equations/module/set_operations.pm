
package set_operations;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
		set_intersection
		set_difference
		set_union
		set_equality
		set_inclusion
		set_belonging
		set_product
);

use List::Util qw(uniq any);
use Data::Dumper;

########################
#    SET OPERATIONS    #
########################

sub set_intersection {
	my ($array_a, $array_b) = @_;
	my @array_c;
	foreach my $var ($array_a->@*) {
# 		push @array_c, $var if grep {/$var/} $array_b->@*;
		push @array_c, $var if any {/$var/} $array_b->@*;
	}
	return sort @array_c;
# 	return sort keys %{{ map {$_ => 1} @array_c }};
}

sub set_difference {	# set complement	# array_a minus array_b
	my ($array_a, $array_b) = @_;
	my @array_c;
	foreach my $var ($array_a->@*) {
# 		push @array_c, $var unless grep {/$var/} $array_b->@*;
		push @array_c, $var unless any {/$var/} $array_b->@*;
	}
	return sort @array_c;
# 	return sort keys %{{ map {$_ => 1} @array_c }};
}

sub set_union {
	my ($array_a, $array_b) = @_;
# 	return sort keys %{{ map {$_ => 1} $array_a->@*, $array_b->@* }};
	return sort uniq $array_a->@*, $array_b->@*;
}

sub set_equality {		# require that sort and uniq were applied to each array beforehand
	my ($array_a, $array_b) = @_;
	if ($array_a->$#* != $array_b->$#*) {
		return 0;
	}
	for (my $i=0; $i <= $array_a->$#*; $i++) {
		if ($array_a->[$i] ne $array_b->[$i]) {
			return 0;
		}
	}
	return 1;
}
  
sub set_inclusion {		# is array_a included in array_b
	my ($array_a, $array_b) = @_;
	if (set_equality($array_a, [set_intersection($array_a, $array_b)]))
	{ return 1 }
	else
	{ return 0 }
}

sub set_belonging {
	my ($element, $array) = @_;
# 	if (grep {/$element/} $array->@*)
	if (any {/$element/} $array->@*)
	{ return 1 }
	else
	{ return 0 }
}


sub set_product {		# cartesian product of n sets
	my @array_of_aref = @_;
	if (@array_of_aref == 0) {
		return;
	}
	elsif (@array_of_aref == 1) {
		return $array_of_aref[0];
	}
	elsif (@array_of_aref >= 2) {
		my $array_a = shift @array_of_aref;
		my $array_b = shift @array_of_aref;
		my @array_c;
		foreach my $a ($array_a->@*) {
			foreach my $b ($array_b->@*) {
				if (ref $a eq "" and ref $b eq "") {
					push @array_c, [$a,     $b];
				}
				elsif (ref $a eq "ARRAY" and ref $b eq "") {
					push @array_c, [$a->@*, $b];
				}
				elsif (ref $a eq "" and ref $b eq "ARRAY") {
					push @array_c, [$a,     $b->@*];
				}
				elsif (ref $a eq "ARRAY" and ref $b eq "ARRAY") {
					push @array_c, [$a->@*, $b->@*];
				}
			}
		}
		while ( defined (my $aref = shift @array_of_aref)) {
			@array_c = set_product(\@array_c, $aref);
		}
		return @array_c;
	}
}



1;

