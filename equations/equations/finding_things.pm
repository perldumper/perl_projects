#!/usr/bin/perl

use strict;
use warnings;

package finding_things;

##########################
#     FINDING THINGS     #
##########################


# we want to found the path of the variable to isolate in the binary expression tree
# the variable is necessarily a leaf


sub find_node_path {
	my %params = (variable=> 0, node=> 0);
	%params = @_;
	my $expression = $params{expression};
	my $variable = $params{which} if $params{variable};
	my $node_id  = $params{which} if $params{node};
	my @stack_tree_walk;
	my $node = $expression;			# start at root node
	push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};

	while(@stack_tree_walk) {

		if ($params{variable}) {
			if ($node->{type} eq "variable" and $node->{value} eq $variable) {	# variable found
				pop @stack_tree_walk; 											# remove variable node
				return map { { $_->%{"type", "value", "side", "id"} } } @stack_tree_walk;
			}
		}
		elsif ($params{node}) {
			if ($node->{id} == $node_id) {										# node found
				pop @stack_tree_walk; 											# remove node
				return map { { $_->%{"type", "value", "side", "id"} } } @stack_tree_walk;
			}
		}

		if ($node->{type} eq "operator") {					# if node is not a leaf, visit children nodes
			if (not $stack_tree_walk[-1]->{left_visited}) {		# first visit left child node
				$stack_tree_walk[-1]->{left_visited} = 1;
				$node = $node->{left};
				push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
			}
			elsif ($node->{side} eq "left") {					# second visit right child node
				$node = $node->{right};
				$stack_tree_walk[-1]->{side} = "right";
				push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
			}
			else {												# left and right have been visited, go back to parent
				pop @stack_tree_walk;
				if (@stack_tree_walk) {
					$node = $stack_tree_walk[-1];
				}
			}
		}
		else {													# if the node is a leaf, go back to parent node
			pop @stack_tree_walk;
			$node = $stack_tree_walk[-1];
		}
	}
	return 0; # variable not found, $operations[0] = 0, which evaluates to false in boolean context
}


sub find_nodes {
	my $equation = shift;
	my $left_expression = $equation->{trees}->{left_side};
	my $right_expression = $equation->{trees}->{right_side};
	my @stack_tree_walk;
	my %nodes;
	my $node;

	foreach my $expression ($left_expression, $right_expression) {
		@stack_tree_walk = ();
		$node = $expression; # start at root node
		push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};

		while(@stack_tree_walk) {

			$nodes{$node->{id}} = { type=> $node->{type},
			                       value=> $node->{value},
			                          id=> $node->{id} };

			if ($node->{type} eq "operator") {				# operator
				if (not $stack_tree_walk[-1]->{left_visited}) {
					$stack_tree_walk[-1]->{left_visited} = 1;
					$node = $node->{left};
					push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
				}
				elsif ($node->{side} eq "left") {
					$node = $node->{right};
					$stack_tree_walk[-1]->{side} = "right";
					push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
				}
				else {
					pop @stack_tree_walk;
					if (@stack_tree_walk) {
						$node = $stack_tree_walk[-1];
					}
				}
			}
			else {											# number
				pop @stack_tree_walk;
				$node = $stack_tree_walk[-1];
			}
		}
	}
	return %nodes ;
}


sub find_variables {
	my $equation = shift;
	my %nodes = $equation->{nodes}->%*;
	my @variables;
	foreach (keys %nodes) {
		push @variables, $nodes{$_}->{value}
			if $nodes{$_}->{type} eq "variable";
	}
	return sort keys %{ { map {$_ => 1} @variables} };
}



sub find_equations_containing_var {
	my ($variable, @set_of_equations) = @_;
	my @set;
	foreach my $eq (@set_of_equations) {
		push @set, $eq
			if grep {/$variable/} $eq->{variables}->@*;
	}
	return @set;
}

1;

