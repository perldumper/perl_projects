#!/usr/bin/perl

use strict;
use warnings;
use bigrat;		# 1/3 --> 1/3, not floor(1.0/3.)

my %precedence = (
	"**"  => 3,
	"*"   => 2,
	"/"   => 2,
	"+"   => 1,
	"-"   => 1,
);

my %left_assoc = (
	"**"  => 0,
	"*"   => 1,
	"/"   => 1,
	"+"   => 1,
	"-"   => 1,
);

my %right_assoc = (
	"**"  => 1,
	"*"   => 1,
	"/"   => 0,
	"+"   => 1,
	"-"   => 0,
);


my @op = qw(+ - * / **);
my @index = 0..$#op;
my ($i, $j, $k, $l);
my $minimum_precedence_operand;

sub minimum_precedence {
	my ($a, $b) = @_;
	if ($precedence{$a} <= $precedence{$b}) {
# 		return $a;
		return $precedence{$a};
	}
	else {
# 		return $b;
		return $precedence{$b};
	}
}

$\="\n";
# 
# for $i (@index) {
# 	for $j (@index) {
# 		for $k (@index) {
# 
# 			if ($op[$i] eq "**" and $op[$j] eq "**" and $op[$k] eq "**") {
# 				next;
# 			}
# 
# 			print("before 5 $op[$i] (4 $op[$j] 3 $op[$k] 2)");
# 
# 			if (    eval("5 $op[$i] (4 $op[$j] 3 $op[$k] 2)")
#                  != eval("5 $op[$i]  4 $op[$j] 3 $op[$k] 2 ") ) {
# 
# 				$minimum_precedence_operand = minimum_precedence($op[$j], $op[$k]);
# 				
# 				if ( (not $right_assoc{$op[$i]} and $precedence{$op[$i]} < $minimum_precedence_operand)
# 					or  ($right_assoc{$op[$i]} and $precedence{$op[$i]} <= $minimum_precedence_operand))
# 				{
# 					print "-" x 50;
# 					print "a $op[$i] b $op[$j] c $op[$k] d\t!=\ta $op[$i] (b $op[$j] c $op[$k] d)";
# 					printf "%-30s%s\n", "5 $op[$i] 4 $op[$j] 3 $op[$k] 2",
#                                        "5 $op[$i] (4 $op[$j] 3 $op[$k] 2)";
# 					printf "%-30s%s\n", eval("5 $op[$i] 4 $op[$j] 3 $op[$k] 2"),
#                                         eval("5 $op[$i] (4 $op[$j] 3 $op[$k] 2)");
# 
# 				}
# 			}
# 
# 			print("after 5 $op[$i] (4 $op[$j] 3 $op[$k] 2)");
# 		}
# 	}
# }
# 
# exit;
# 
# for $i (@index) {
# 	for $j (@index) {
# 		for $k (@index) {
# 
# 			if ($op[$i] eq "**" and $op[$j] eq "**" and $op[$k] eq "**") {
# 				next;
# 			}
# 
# 			if (    eval("(5 $op[$i] 4 $op[$j] 3) $op[$k] 2")
#                  != eval(" 5 $op[$i] 4 $op[$j] 3  $op[$k] 2") ) {
# 
# 				$minimum_precedence_operand = minimum_precedence($op[$i], $op[$j]);
# 
# 				if ( (not $left_assoc{$op[$k]} and $precedence{$op[$k]} < $minimum_precedence_operand)
# 					or  ($left_assoc{$op[$k]} and $precedence{$op[$k]} <= $minimum_precedence_operand))
# 				{
# 					print "-" x 50;
# 					print "a $op[$i] b $op[$j] c $op[$k] d\t!=\t(a $op[$i] b $op[$j] c) $op[$k] d"
# 
# 					printf "%-30s%s\n", "5 $op[$i] 4 $op[$j] 3 $op[$k] 2",
#                                        "(5 $op[$i] 4 $op[$j] 3) $op[$k] 2";
# 					printf "%-30s%s\n", eval("5 $op[$i] 4 $op[$j] 3 $op[$k] 2"),
#                                        eval("(5 $op[$i] 4 $op[$j] 3) $op[$k] 2");
# 				}
# 			}
# 		}
# 	}
# }
# 







for $i (@index) {
	for $j (@index) {
# 		if ($op[$i] eq "**" and $op[$j] eq "**") {
# 			next;
# 		}

		print "-" x 50;
		printf "%-30s%s\n", "5 $op[$i] 4 $op[$j] 3",
                            "5 $op[$i] (4 $op[$j] 3)";
		printf "%-30s%s\n", eval("5 $op[$i] 4 $op[$j] 3"),
                            eval("5 $op[$i] (4 $op[$j] 3)");
	}
}


for $i (@index) {
	for $j (@index) {
		print "-" x 50;
		printf "%-30s%s\n", "5 $op[$i] 4 $op[$j] 3",
                           "(5 $op[$i] 4) $op[$j] 3";
		printf "%-30s%s\n", eval("5 $op[$i] 4 $op[$j] 3"),
                            eval("(5 $op[$i] 4) $op[$j] 3");
	}
}













