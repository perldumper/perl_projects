#!/usr/bin/perl

# "Separate Chaining" impementation of an associative array

# EXAMPLE
# ./assoc_array_separate_chaining.pl key1 val1 key2 val2

use strict;
use warnings;
use Data::Dumper;

package Hash;
use strict;
use warnings;

sub new {
	my $class = shift;
	my $size = shift;
	my @array;
	$#array = $size;		# equivalent to @array = (undef) * ($size+1)
	$array[0] = $size;		# store the number of buckets inside the array of buckets
							# "in-band" signaling, for avoiding to choose between
							# 1) make a hash object  { size => $size, buckets => [ buckets go here ] }
							# 2) make an array of array object [ $size, [ buckets go here ] ]
	return bless \@array, $class;
}

# Bob Jenkin's one_at_a_time hash function ????
# source --> https://www.perl.com/pub/2002/10/01/hashes.html/
sub perlhash {
	my $key = shift;
	my $hash = 0;
	foreach (split //, $key) {
		$hash = $hash*33 + ord($_);
	}
	return $hash;
}

sub store {			# do not take into account if the key already exists
	my $self = shift;
	my ($key, $value) = @_;
	my $size = $self->[0];
	my $hash = perlhash($key);
	my $index = ($hash % $size) + 1;		# index 0 contains the number of buckets (not part of the bucket array)
# 	print "KEY $key  HASH $hash   INDEX $index\n";
	foreach ($self->[$index]->@*) {
		if ($_->[1] eq $key) {		# key already exists
			$_->[2] = $value;		# overwrite previous value
			return;
		}
	}
	push $self->[$index]->@*, [ $hash, $key, $value ];	# the key doesn't exists
}

sub fetch {
	my $self = shift;
	my $key = shift;
	my $size = $self->[0];
	my $hash = perlhash($key);
	my $index = ($hash % $size) + 1;		# index 0 contains the number of buckets (not part of the bucket array)
	foreach ($self->[$index]->@*) {
		if ($_->[1] eq $key) {
			return $_->[2];
		}
	}
	die "key $key not found\n";
}

sub keys {
	my $self = shift;
	my @keys;
	foreach my $bucket ($self->@[1 .. $self->$#*]) {
		next unless defined $bucket;
		foreach my $pair ($bucket->@*) {	# key/value pair
			push @keys, $pair->[1];
		}
	}
	return @keys;
}

sub values {
	my $self = shift;
	my @values;
	foreach my $bucket ($self->@[1 .. $self->$#*]) {
		next unless defined $bucket;
		foreach my $pair ($bucket->@*) {	# key/value pair
			push @values, $pair->[2];
		}
	}
	return @values;
}

sub exists {
	my $self = shift;
	my $key = shift;
	foreach my $bucket ($self->@[1 .. $self->$#*]) {
		next unless defined $bucket;
		foreach my $pair ($bucket->@*) {	# key/value pair
			if ($pair->[1] eq $key) {
				return 1;
			}
		}
	}
	return 0;
}

sub clear {
	my $self = shift;
	foreach ($self->@[1 .. $self->$#*]) {
		undef $_;
	}
}

package main;

exit unless @ARGV >= 2 and @ARGV % 2 == 0;

my $associative_array = Hash->new(8);

while (my $key = shift @ARGV) {
	my $value = shift @ARGV;
	$associative_array->store($key, $value);
}

$\="\n";
$,="\n";

print "KEYS";
print $associative_array->keys();
print "";
print "VALUES";
print $associative_array->values();
print "";
print "KEY / VALUE pairs";

# print Dumper $associative_array;

foreach my $key ($associative_array->keys()) {
	my $value = $associative_array->fetch($key);
	print "\"$key\"\t=>\t\"$value\""
}

$associative_array->store(($associative_array->keys())[0], "new value");

print "";
print "KEY / VALUE pairs";
foreach my $key ($associative_array->keys()) {
	my $value = $associative_array->fetch($key);
	print "\"$key\"\t=>\t\"$value\""
}


# print Dumper $associative_array;
# $associative_array->clear();
# print Dumper $associative_array;

__END__

TESTS

$associative_array->store();
$associative_array->fetch();
$associative_array->keys();
$associative_array->values();
$associative_array->exists();
$associative_array->clear();

$associative_array->store("key2", "fisrt value");
$associative_array->store("key2", "new value");


