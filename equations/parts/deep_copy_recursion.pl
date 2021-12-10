#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

#perl -le '@array=(1,2,3); $ref=\$array[0]; print @array; $ref->$*=5; print @array'
#perl -le '$aref=[1,2,3]; $ref=\$aref->[0]; print $aref->@*; $ref->$*=5; print $aref->@*'


sub copy_data_structure {	# deep copy of a data structure
		
	my $dsc = shift;
	my $copy;
	
	if (ref $dsc eq "ARRAY") {
		foreach my $idx (keys $dsc->@*) {
			$copy->[$idx] = copy_data_structure($dsc->[$idx]);
		}
	}
	elsif (ref $dsc eq "HASH") {
		foreach my $key (keys $dsc->%*) {
			$copy->{$key} = copy_data_structure($dsc->{$key});
		}
	}
	elsif (ref $dsc eq "SCALAR") {
		$copy = copy_data_structure($dsc->$*);
	}
	elsif (ref $dsc eq "REF") {
		$copy = copy_data_structure($dsc->$*);
	}
	elsif (ref $dsc eq "") {
		$copy = $dsc;
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


print Dumper $data_structure;
print Dumper $copy;

$copy->{trees}->{left_side}->{value} = "z";
print Dumper $copy;
print Dumper $data_structure;




