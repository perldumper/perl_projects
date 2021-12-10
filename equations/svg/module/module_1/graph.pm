#!/usr/bin/perl

use strict;
use warnings;

package graph;

use Exporter 'import';
our @EXPORT = qw(
		mark_nodes
		mark_nodes2
		mark_nodes3
		make_graph
		make_overall_graph
		copy_data_structure
);
use List::Util qw(any);
use Data::Dumper;
# use File::Temp q(tempfile);
# use Time::HiRes q(usleep);

#################
#     GRAPH     #
#################


sub mark_nodes3 {
	my $equation = shift;
	my $id = 0;

	sub tree_walk2 {
		my $node = shift;
		my $id = shift;
		$node->{id} = $id;
		$id++;
		if ($node->{type} eq "binary_op") { # node has children
			$id = tree_walk2($node->{left}, $id);
			$id = tree_walk2($node->{right}, $id);
		}
		elsif ($node->{type} eq "unary_op") { # node has children
			$id = tree_walk2($node->{operand}, $id);
		}
		return $id
	}
# 	tree_walk2($equation->{trees}->{left_side}, $id);
# 	tree_walk2($equation->{trees}->{right_side}, $id);
	$id = tree_walk2($equation->{trees}->{left_side}, $id);
	tree_walk2($equation->{trees}->{right_side}, $id);
}


sub mark_nodes2 {
	my $equation = shift;
	our $id = 0;	# global variable within the enclosing block, get reset to 0 for each equation
# 	my $id = 0;		# not reset, the nodes id of the next equation don't start at 0

# 	print "make_nodes2";
# 	print Dumper $equation;

	sub tree_walk {
		my $node = shift;
		$node->{id} = $id;
		$id++;
		if ($node->{type} eq "binary_op") { # node has children
			tree_walk($node->{left});
			tree_walk($node->{right});
		}
		elsif ($node->{type} eq "unary_op") { # node has children
			tree_walk($node->{operand});
		}
	}
	tree_walk($equation->{trees}->{left_side});
	tree_walk($equation->{trees}->{right_side});
}


sub mark_nodes {
	# visit all the nodes
	my $equation = shift;
	my $left_expression  = $equation->{trees}->{left_side};
	my $right_expression = $equation->{trees}->{right_side};
	my @stack_tree_walk;
	my $node;
	my $id = 0;
	
	foreach my $expression ($left_expression, $right_expression) {
		@stack_tree_walk = ();
		$node = $expression;
		push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left", id_set=> 0};
		while(@stack_tree_walk) {

			unless ($stack_tree_walk[-1]->{id_set}) {	# unless $node->{id_set} wouldn't have worked
				$node->{id}     = $id;					# modify actual node by reference
				$stack_tree_walk[-1]->{id_set} = 1;		# $node->{id_set} = 1 wouldn't have worked, because next time the node
														# is visited by moving back up the tree and the value of id_set read,
														# $node would have come from the stack copy which was copied before
														# that the key id_set would have been set to 1
				$id++;
			}

			if ($node->{type} eq "binary_op") {			# interior node
				
				if (not $stack_tree_walk[-1]->{left_visited}) {
					$node = $node->{left};
					$stack_tree_walk[-1]->{left_visited} = 1;
					push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left", id_set=> 0};
				}
				elsif ($node->{side} eq "left") {
					$node = $node->{right};
					$stack_tree_walk[-1]->{side} = "right";
					push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left", id_set=> 0};
				}
				else {
					pop @stack_tree_walk;
					$node = $stack_tree_walk[-1];
				}
			}
			elsif ($node->{type} eq "unary_op") {
				if (not $stack_tree_walk[-1]->{operand_visited}) {
					$node = $node->{operand};
					$stack_tree_walk[-1]->{operand_visited} = 1;
					push @stack_tree_walk, {$node->%*, operand_visited => 0, id_set=> 0};
				}
				else {
					pop @stack_tree_walk;
					if (@stack_tree_walk) {
						$node = $stack_tree_walk[-1];
					}
				}
			}
			else {										# leaf
				pop @stack_tree_walk;
				if (@stack_tree_walk) {					# empty stack at the end, when both left and right subtrees of root node
					$node = $stack_tree_walk[-1];		#   have been visited
				}
			}
		}
	}
}

sub make_graph {
	# visit all the nodes
	my $equation = shift;
	my $left_expression  = $equation->{trees}->{left_side};
	my $right_expression = $equation->{trees}->{right_side};
	my @stack_tree_walk;
	my $node;

	push $equation->{graph}->{$left_expression->{id}}->@*,
			$right_expression->{id}
# 		unless grep {/$right_expression->{id}/}
		unless any {/$right_expression->{id}/}
			$equation->{graph}->{$left_expression->{id}}->@*;

	push $equation->{graph}->{$right_expression->{id}}->@*,
			$left_expression->{id}
# 		unless grep {/$left_expression->{id}/}
		unless any {/$left_expression->{id}/}
			$equation->{graph}->{$right_expression->{id}}->@*;
	
	foreach my $expression ($left_expression, $right_expression) {
		@stack_tree_walk = ();
		$node = $expression;
		push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
		while(@stack_tree_walk) {

			if (@stack_tree_walk >= 2) {
				push $equation->{graph}->{$stack_tree_walk[-2]->{id}}->@*,
						$stack_tree_walk[-1]->{id}
# 					unless grep {/$stack_tree_walk[-1]->{id}/}
					unless any {/$stack_tree_walk[-1]->{id}/}
						$equation->{graph}->{$stack_tree_walk[-2]->{id}}->@*;
			}

			if ($node->{type} eq "binary_op") {			# interior node
				
				if (not $stack_tree_walk[-1]->{left_visited}) {
					$node = $node->{left};
					$stack_tree_walk[-1]->{left_visited} = 1;
					push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
				}
				elsif ($node->{side} eq "left") {
					$node = $node->{right};
					$stack_tree_walk[-1]->{side} = "right";
					push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
				}
				else {
					pop @stack_tree_walk;
					$node = $stack_tree_walk[-1];
				}
			}
			elsif ($node->{type} eq "unary_op") {
				if (not $stack_tree_walk[-1]->{operand_visited}) {
					$node = $node->{operand};
					$stack_tree_walk[-1]->{operand_visited} = 1;
					push @stack_tree_walk, {$node->%*, operand_visited => 0};
				}
				else {
					pop @stack_tree_walk;
					if (@stack_tree_walk) {
						$node = $stack_tree_walk[-1];
					}
				}
			}
			else {										# leaf
				pop @stack_tree_walk;
				if (@stack_tree_walk) {
					$node = $stack_tree_walk[-1];
				}
			}
		}
	}
}

sub make_overall_graph {
	my @set_of_equations = @_;
	my $id = 0;
	my ($eq, $searched_eq, $var);
	foreach $eq (@set_of_equations) {
		$eq->{id} = $id;
		$id++;
	}
	my %equations_relations_graph;	# graph

	# create of graph of relations between equations
	foreach $eq (@set_of_equations) {
		SEARCHED_EQUATION:
		foreach $searched_eq ( grep { $_->{string} ne $eq->{string} }  @set_of_equations) {

			foreach $var ($eq->{variables}->@*) {
# 				if (grep {/$var/} $searched_eq->{variables}->@*) {
				if (any {/$var/} $searched_eq->{variables}->@*) {
					push $equations_relations_graph{$eq->{id}}->@*,          $searched_eq->{id};
					push $equations_relations_graph{$searched_eq->{id}}->@*, $eq->{id};

# 					push $equations_relations_graph{$eq->{string}}->@*,          $searched_eq->{string};
# 					push $equations_relations_graph{$searched_eq->{string}}->@*, $eq->{string};
					next SEARCHED_EQUATION;
				}
			}
		}
	}

	$eq = shift @set_of_equations;
	$eq = copy_data_structure($eq);


	while (defined ($eq = shift @set_of_equations)) {
		$eq = copy_data_structure($eq);
	}



# 	print Dumper \%equations_relations_graph;

	

}


sub copy_data_structure {	# deep copy of a data structure
	my $struct = shift;
	my $copy;
	if (ref $struct eq "ARRAY") {
		foreach my $idx (keys $struct->@*) {
			$copy->[$idx] = copy_data_structure($struct->[$idx]);
		}
	}
	elsif (ref $struct eq "HASH") {
		foreach my $key (keys $struct->%*) {
			$copy->{$key} = copy_data_structure($struct->{$key});
		}
	}
	elsif (ref $struct eq "") {		# scalar value, not a reference
		$copy = $struct;
	}
	elsif (ref $struct eq "SCALAR") {
		$copy = copy_data_structure($struct->$*);
	}
	elsif (ref $struct eq "REF") {
		$copy = copy_data_structure($struct->$*);
	}
	return $copy;
}

1;

