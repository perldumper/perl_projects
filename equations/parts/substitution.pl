#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
#use feature "declared_refs";
#no warnings "experimental::declared_refs";
#use feature "refaliasing";
#no warnings "experimental::refaliasing";

sub inorder {
	my $expression = shift;
	my $node = $expression;
	if ($node->{type} eq "operator") {
		print "(";
		inorder($node->{left});
		print $node->{value};
		inorder($node->{right});
		print ")";
	}
	else {
		print $node->{value};
	}
}

sub substitution {
	my ($inserted_equation, $master_equation) = @_;
	my $inserted_expression = $inserted_equation->{right_side};
	my $insertion_point     = $inserted_equation->{left_side}->{value};
	my $master_expression   = $master_equation->{right_side};
	my %copy                = $master_equation->%*;

	my @stack_tree_walk;
	my $node = $master_expression;		# WORKS
#	my $node = \%copy;
#	my $node = {$master_expression->%*};
	push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};

	while(@stack_tree_walk) {
		if ($node->{type} eq "variable" and $node->{value} eq $insertion_point) {
  			$node->%* = $inserted_expression->%*;	# WORKS
			pop @stack_tree_walk;
			$node = $stack_tree_walk[-1];		# WORKS
#			$node = {$stack_tree_walk[-1]->%*};
		}
		elsif ($node->{type} eq "operator") {
			if (not $stack_tree_walk[-1]->{left_visited}) {
				$stack_tree_walk[-1]->{left_visited} = 1;
				$node = $node->{left};			# WORKS
#				$node = {$node->{left}->%*};
				push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
			}
			elsif ($node->{side} eq "left") {
				$node = $node->{right};			# WORKS
#				$node = {$node->{right}->%*};
				$stack_tree_walk[-1]->{side} = "right";
				push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
			}
			else {
				pop @stack_tree_walk;
#				$node = $stack_tree_walk[-1];	# WORKS
				if (@stack_tree_walk) {
					$node = $stack_tree_walk[-1];	# WORKS
#					$node = {$stack_tree_walk[-1]->%*};
				}
			}
		}
		else {
			pop @stack_tree_walk;
			$node = $stack_tree_walk[-1];		# WORKS
#			$node = {$stack_tree_walk[-1]->%*};
		}
	}
#	return {right_side=>$master_expression, left_side=>$master_equation->{left_side}};			# WORKS
#	return {right_side=>{$master_expression->%*}, left_side=>$master_equation->{left_side}};
	return { %copy };
}


my $equation = {left_side => { type=> "variable",
							value=> "y"},

				right_side=> { type=> "operator",
							value=> "*",
							left=> {type=> "variable", value=> "a"},
							right=> {type=> "variable", value=> "b"} }

				};

my $insertion = {left_side => { type=> "variable" ,
							value=> "a" },

				right_side=> { type=> "operator",
							value=> "+",
							left=> {type=> "variable", value=> "x"},
							right=> {type=> "variable", value=> "y"} }
				};
$,="";
$\="";
print "equations before substitution\n";
inorder($equation->{left_side});
print "=";
inorder($equation->{right_side});
print "\n";
inorder($insertion->{left_side});
print "=";
inorder($insertion->{right_side});
print "\n";
print "------------------\n";

$,="\n";
$\="\n\n";
my $final = substitution($insertion, $equation);
#substitution($insertion, $equation);

$,="";
$\="";
#print "------------------\n";
print "equation substituted\n";
inorder($final->{left_side});
print "=";
inorder($final->{right_side});
print "\n";

print "------------------\n";
print "original equations\n";
inorder($equation->{left_side});
print "=";
inorder($equation->{right_side});
print "\n";
inorder($insertion->{left_side});
print "=";
inorder($insertion->{right_side});
print "\n";


my $right = {left_side => { type=> "variable",
							value=> "y"},

				right_side=> { type=> "operator",
							value=> "*",
							left=> { type=> "operator",
									value=> "+",
									left=> {type=> "variable", value=> "x"},
									right=> {type=> "variable", value=> "y"} },
							right=> {type=> "variable", value=> "b"} }

				};

#$,="";
#$\="";
#print "------------------\n";
#print "equation substituted\n";
#inorder($right->{left_side});
#print "=";
#inorder($right->{right_side});
#print "\n";
