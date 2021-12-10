#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

#perl -le '@array=(1,2,3); $ref=\$array[0]; print @array; $ref->$*=5; print @array'
#perl -le '$aref=[1,2,3]; $ref=\$aref->[0]; print $aref->@*; $ref->$*=5; print $aref->@*'


sub copy_data_structure {
	my $data_structure = shift;
	my $dsc_pointer = $data_structure;

	my $temp;

	my $copy;
	my $copy_pointer;

	my @stack_tree_walk;
	my $idx;
	my $key;


	if (ref $dsc_pointer eq "" ) {
		push @stack_tree_walk, {node=> $dsc_pointer, got_descendants=> 1};
		$temp = $dsc_pointer;
	}
	elsif (ref $dsc_pointer eq "ARRAY" ) {
		push @stack_tree_walk, {node=> $dsc_pointer, indexes=> [], got_descendants=> 0};
		$temp = [$dsc_pointer->@*];
	}
	elsif (ref $dsc_pointer eq "HASH" ) {
		push @stack_tree_walk, {node=> $dsc_pointer, keys=> [], got_descendants=> 0};
		$temp = {$dsc_pointer->%*};
	}
	elsif (ref $dsc_pointer eq "SCALAR" ) {
		push @stack_tree_walk, {node=> $dsc_pointer, got_descendants=> 1};
		$temp = $dsc_pointer->$*;
	}

	$copy = $temp;

	while(@stack_tree_walk) {

		if (ref $dsc_pointer eq "" ) {
			print $dsc_pointer;
			pop @stack_tree_walk;
			if (@stack_tree_walk) {
				$dsc_pointer = $stack_tree_walk[-1]->{node};
			}
		}

		elsif (ref $dsc_pointer eq "ARRAY" ) {
			unless ($stack_tree_walk[-1]->{got_descendants}) {
				$stack_tree_walk[-1]->{indexes}->@* = keys $dsc_pointer->@*;
				$stack_tree_walk[-1]->{got_descendants} = 1;
			}
			if ($stack_tree_walk[-1]->{indexes}->@*) {
				$idx = shift $stack_tree_walk[-1]->{indexes}->@*;
				$dsc_pointer = $dsc_pointer->[$idx];
				push @stack_tree_walk, {node=> $dsc_pointer, got_descendants=> 0, index=> $idx}
			}
			else {
				pop @stack_tree_walk;
				if (@stack_tree_walk) {
					$dsc_pointer = $stack_tree_walk[-1]->{node};
				}
			}
		}
		$copy=$temp;
		elsif (ref $dsc_pointer eq "HASH" ) {
			unless ($stack_tree_walk[-1]->{got_descendants}) {
				$stack_tree_walk[-1]->{keys}->@* = keys $dsc_pointer->%*;
				$stack_tree_walk[-1]->{got_descendants} = 1;
			}
			if ($stack_tree_walk[-1]->{keys}->@*) {
				$key = shift $stack_tree_walk[-1]->{keys}->@*;
				$dsc_pointer = $dsc_pointer->{$key};
				push @stack_tree_walk, {node=> $dsc_pointer, got_descendants=> 0}
			}
			else {
				pop @stack_tree_walk;
				if (@stack_tree_walk) {
					$dsc_pointer = $stack_tree_walk[-1]->{node};
				}
			}
		}
		elsif (ref $dsc_pointer eq "SCALAR" ) {
			if () {
				$dsc_pointer = $dsc_pointer->$*;
				push @stack_tree_walk, {node=> $dsc_pointer, got_descendants=> 0};
			}
		}
		elsif (ref $dsc_pointer eq "REF" ) {
			$dsc_pointer = $dsc_pointer->$*;
			push @stack_tree_walk, {node=> $dsc_pointer};
		}
	}

	return $copy;
}

my $data_structure = {trees=>{left_side=>{type=> "variable", value=> "y"},
							
						right_side=>{ type=> "operator", value=> "+",
										left=> {type=> "operator", value=> "*", left=> {type=> "number", value=> 5},
																				rigth=> {type=> "variable", "value"=>"x"}},
										right=> {type=> "number", value=> "10"} }
						}};

#print Dumper $data_structure;

$\="\n";

my $copy = copy_data_structure($data_structure);


#print Dumper $data_structure;
#print Dumper $copy;

#$copy->{trees}->{left_side}->{value} = "z";
#print Dumper $copy;
#print Dumper $data_structure;




