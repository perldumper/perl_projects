#!/usr/bin/perl

use strict;
use warnings;
use File::Temp q(tempfile);

my ($fh, $tmp)=tempfile();
die "cannot create tempfile" unless $fh;
#print ($fh <STDIN>) || die "write temp: $!";

$,="\n";
#$,="";
$\="\n";
#$\="";




my $equation = {trees=>{left_side=>{type=> "variable", value=> "y"},
							
						right_side=>{ type=> "operator", value=> "+",
										left=> {type=> "operator", value=> "*", left=> {type=> "number", value=> 5},
																				rigth=> {type=> "variable", "value"=>"x"}},
										right=> {type=> "number", value=> "10"} }
						}};

#my %graph = ( 0=> [1,2],  1=> [0], 2=> [1,3], 3=> [1,2,3]  );
my %graph = ( 0=> 1, 0=> 2,  1=> 0, 2=> 1, 2=> 3, 3=> 1, 3=> 2, 3=> 3 );


print ($fh %graph ) || die "write temp: $!";
close $fh;

open my $FH, "<", $tmp;

print <$FH>;

close $FH;

unlink($tmp);





