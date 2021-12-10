#!/usr/bin/perl

use strict;
use warnings;


package finding_things;

use maths_operations;
use List::Util qw(uniq any);
use Data::Dumper;
use Exporter 'import';
our @EXPORT = qw(
		find_node_path
		find_nodes
		find_variables
		find_equations_containing_var
		tree_walk_sub
		tree_starts_with
		tree_match
		tree_substitute
);


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
# 	push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
	push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0, side => "left", operand_visited => 0};

	while(@stack_tree_walk) {

		if ($params{variable}) {
			if ($node->{type} eq "variable" and $node->{value} eq $variable) {	# variable found
				pop @stack_tree_walk; 											# remove variable node
# 				return map { { $_->%{"type", "value", "side", "id"} } } @stack_tree_walk;
				# exclude left_visited, left (subtre), right (subtree)
				return map { { $_->%{"type", "value", "id"}, exists $_->{side} ? $_->%{side} : () } } @stack_tree_walk;
				# node of type unary_op don't have a side value
			}
		}
		elsif ($params{node}) {
			if ($node->{id} == $node_id) {										# node found
				pop @stack_tree_walk; 											# remove node
# 				return map { { $_->%{"type", "value", "side", "id"} } } @stack_tree_walk;
				# exclude left_visited, left (subtre), right (subtree)
				return map { { $_->%{"type", "value", "id"}, exists $_->{side} ? $_->%{side} : () } } @stack_tree_walk;
				# node of type unary_op don't have a side value
			}
		}

		if ($node->{type} eq "binary_op") {					# if node is not a leaf, visit children nodes
			if (not $stack_tree_walk[-1]->{left_visited}) {		# first visit left child node
				$node = $node->{left};
				$stack_tree_walk[-1]->{left_visited} = 1;
				push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0, side => "left"};
			}
			elsif (not $stack_tree_walk[-1]->{right_visited}) {		# first visit left child node
				$node = $node->{right};
				$stack_tree_walk[-1]->{side} = "right";
				$stack_tree_walk[-1]->{right_visited} = 1;
				push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0, side => "left"};
			}
			else {												# left and right have been visited, go back to parent
				pop @stack_tree_walk;
				if (@stack_tree_walk) {
					$node = $stack_tree_walk[-1];
				}
			}
		}
		elsif ($node->{type} eq "unary_op") {
			if (not $stack_tree_walk[-1]->{operand_visited}) {	# first visit only child node = its unique operand
				$node = $node->{operand};
				$stack_tree_walk[-1]->{operand_visited} = 1;
				push @stack_tree_walk, {$node->%*, operand_visited => 0};
			}
			else {												# operand have been visited, go back to parent
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

# 	print Dumper $equation;

	foreach my $expression ($left_expression, $right_expression) {
		@stack_tree_walk = ();
		$node = $expression; # start at root node
# 		push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
		push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left", operand_visited => 0};

		while(@stack_tree_walk) {

# 			print "-" x 40;
# 			print $node->%*;
# 			print "VALUE $node->{value}";

			$nodes{$node->{id}} = { type=> $node->{type},
								   value=> $node->{value},
									  id=> $node->{id} };

			if ($node->{type} eq "binary_op") {				# operator
# 				print "BINARY OP";
				if (not $stack_tree_walk[-1]->{left_visited}) {
# 					print "visiting left";
					$node = $node->{left};
					$stack_tree_walk[-1]->{left_visited} = 1;
					push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
				}
# 				elsif ($node->{side} eq "left") {
				elsif ($stack_tree_walk[-1]->{side} eq "left" ) {
# 				elsif (not $stack_tree_walk[-1]->{side} eq "left" ) {
# 					print "visiting right";
					$node = $node->{right};
					$stack_tree_walk[-1]->{side} = "right";
					push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
				}
				else {
# 					print "going up";
# 					print "RIGHT $stack_tree_walk[-1]->{side}";
					pop @stack_tree_walk;
					if (@stack_tree_walk) {
						$node = $stack_tree_walk[-1];
					}
				}
			}
			elsif ($node->{type} eq "unary_op") {
# 				print "UNARY OP";
				if (not $stack_tree_walk[-1]->{operand_visited}) {	# first visit only child node = its unique operand
# 					print "visiting operand";
					$node = $node->{operand};
					$stack_tree_walk[-1]->{operand_visited} = 1;
					push @stack_tree_walk, {$node->%*, operand_visited => 0, left_visited => 0, side=> "left"};
				}
				else {												# operand have been visited, go back to parent
# 					print "going up";
					pop @stack_tree_walk;
					if (@stack_tree_walk) {
						$node = $stack_tree_walk[-1];
					}
				}
			}
			else {											# number
# 				print "VARIABLE or NUMBER";
				pop @stack_tree_walk;
				$node = $stack_tree_walk[-1];
			}
		}
	}
# 	print Dumper %nodes;
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
# 	return sort keys %{ { map {$_ => 1} @variables} };
	return sort uniq @variables;
}


sub find_equations_containing_var {
	my ($variable, @set_of_equations) = @_;
	my @set;
	foreach my $eq (@set_of_equations) {
		push @set, $eq
# 			if grep {/$variable/} $eq->{variables}->@*;
			if any {/$variable/} $eq->{variables}->@*;
	}
	return @set;
}

# mark new nodes that are substituted with first node_id available starting from 0

sub tree_match {
	my ($tree, $tree_pattern) = @_;
	my @stack_tree_walk;
	my $node = $tree;
	my @node_id;
	my @capture;
	push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0, operand_visited => 0};

	while(@stack_tree_walk) {

		if ($node->{type} eq "binary_op") {				# operator
			if (not $stack_tree_walk[-1]->{left_visited}) {

				if (defined (@capture = tree_starts_with($node, $tree_pattern) ) ) {
					push @node_id, { id => $node->{id}, capture => [@capture] } ;
				}

				$node = $node->{left};
				$stack_tree_walk[-1]->{left_visited} = 1;
				push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0};
			}
			elsif (not $stack_tree_walk[-1]->{right_visited}) {
				$node = $node->{right};
				$stack_tree_walk[-1]->{right_visited} = 1;
				push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0};
			}
			else {
				pop @stack_tree_walk;
				if (@stack_tree_walk) {
					$node = $stack_tree_walk[-1];
				}
			}
		}
		elsif ($node->{type} eq "unary_op") {			# function
			if (not $stack_tree_walk[-1]->{operand_visited}) {

# 				if (tree_starts_with($node, $tree_pattern)) {
# 					push @node_id, $node->{id};
# 				}
				if (defined (@capture=tree_starts_with($node, $tree_pattern) ) ) {
					push @node_id, { id => $node->{id}, capture => [@capture] } ;
				}

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
		else {											# number

# 			if (tree_starts_with($node, $tree_pattern)) {
# 				push @node_id, $node->{id};
# 			}
			if (defined (@capture=tree_starts_with($node, $tree_pattern) ) ) {
				push @node_id, { id => $node->{id}, capture => [@capture] } ;
			}

			pop @stack_tree_walk;
			$node = $stack_tree_walk[-1];
		}
	}
	return @node_id;
}

sub tree_starts_with {
	my ($tree_to_match, $tree_pattern) = @_;
	my @stack_treewalk_pattern;
	my @stack_treewalk_match;
	my $node_match = $tree_to_match;
	my $node_pattern = $tree_pattern;
	push @stack_treewalk_pattern, {$node_pattern->%*, left_visited => 0, right_visited => 0, operand_visited => 0};
	push @stack_treewalk_match, $node_match;
	my @capture = undef;

	while (@stack_treewalk_pattern) {

# 		print "=" x 40;
# 		print $node_pattern->{value};

		if ($node_pattern->{type} eq "binary_op") {  # OPERATOR
# 			print "binary op";

			if (not $stack_treewalk_pattern[-1]->{left_visited}) {
# 				print "visiting left";

				foreach (grep { ref $node_pattern->{$_} eq "" ? $_ : () } keys $node_pattern->%*) {
					if ($node_match->{$_} ne $node_pattern->{$_}) {
# 						print "UNDEF";
# 						local $,=" ";
# 						print grep { ref $node_pattern->{$_} eq "" ? $_ : () } keys $node_pattern->%*;
# 						print $node_match->%*;
						return undef;
					}
				}
				if (exists $node_pattern->{capture}
				and exists $node_match->{ $node_pattern->{capture}->[1] }) {
					$capture[ $node_pattern->{capture}->[0] ]
					= $node_match->{ $node_pattern->{capture}->[1] }
				}
				if ($node_pattern->{left}) {		# go to left subtree if it exists
# 					print "there is a left sub tree";
					$node_match   = $node_match->{left};
					$node_pattern = $node_pattern->{left};
					$stack_treewalk_match[-1]->{left_visited} = 1;
					push @stack_treewalk_pattern, {$node_pattern->%*, left_visited => 0, right_visited=> 0};
					push @stack_treewalk_match, $node_match;
				}
				else {
# 					print "there is NOT a left sub tree";
					$stack_treewalk_pattern[-1]->{left_visited} = 1;# not true, but this makes sure we won't go left on this node
					redo;
				}
			}
			elsif (not $stack_treewalk_pattern[-1]->{right_visited}) {
# 				print "visiting right";

				if ($node_pattern->{right}) {		# go to right subtree if it exists
# 					print "there is a right sub tree";
					$node_match   = $node_match->{right};
					$node_pattern = $node_pattern->{right};
					$stack_treewalk_pattern[-1]->{right_visited} = 1;
					push @stack_treewalk_pattern, {$node_pattern->%*, left_visited => 0, right_visited=> 0};
					push @stack_treewalk_match, $node_match;
				}
				else {
# 					print "there is NOT a right sub tree";
					$stack_treewalk_pattern[-1]->{right_visited} = 1;
					redo;
				}
			}
			else {
# 				print "going up";
				pop @stack_treewalk_match;
				pop @stack_treewalk_pattern;
				if (@stack_treewalk_pattern) {
					$node_match   = $stack_treewalk_match[-1];
					$node_pattern = $stack_treewalk_pattern[-1];
				}
			}
		}
		elsif ($node_pattern->{type} eq "unary_op") {  # FUNCTION

			if (not $stack_treewalk_pattern[-1]->{operand_visited}) {	# first visit only child node_pattern = its unique operand

				foreach (grep { ref $node_pattern->{$_} eq "" ? $_ : () } keys $node_pattern->%*) {
					if ($node_match->{$_} ne $node_pattern->{$_}) {
						return undef;
					}
				}
				if (exists $node_pattern->{capture}
				and exists $node_match->{ $node_pattern->{capture}->[1] }) {
					$capture[ $node_pattern->{capture}->[0] ]
					= $node_match->{ $node_pattern->{capture}->[1] }
				}
				if ($node_pattern->{operand}) {
					$node_match   = $node_match->{operand};
					$node_pattern = $node_pattern->{operand};
					$stack_treewalk_pattern[-1]->{operand_visited} = 1;
					push @stack_treewalk_pattern, {$node_pattern->%*, operand_visited => 0};
					push @stack_treewalk_match, $node_match;
				}
				else {
					$stack_treewalk_pattern[-1]->{operand_visited} = 1;
					redo;
				}
			}
			else {												# operand have been visited, go back to parent
				pop @stack_treewalk_match;
				pop @stack_treewalk_pattern;
				if (@stack_treewalk_pattern) {
					$node_match   = $stack_treewalk_match[-1];
					$node_pattern = $stack_treewalk_pattern[-1];
				}
			}
		}
		else {  # NUMBER
			foreach (grep { ref $node_pattern->{$_} eq "" ? $_ : () } keys $node_pattern->%*) {
				if ($node_match->{$_} ne $node_pattern->{$_}) {
					return undef;
				}
			}
			if (exists $node_pattern->{capture}
			and exists $node_match->{ $node_pattern->{capture}->[1] }) {
				$capture[ $node_pattern->{capture}->[0] ]
				= $node_match->{ $node_pattern->{capture}->[1] }
			}
			pop @stack_treewalk_match;
			pop @stack_treewalk_pattern;
			$node_match   = $stack_treewalk_match[-1];
			$node_pattern = $stack_treewalk_pattern[-1];
		}
	}
# 	print "END";
	return @capture;
}

sub tree_substitute {
	my ($tree_to_substitute, $tree_pattern, $tree_to_replace) = @_;
	my @stack_tree_walk;
	my @nodes = tree_match($tree_to_substitute, $tree_pattern);
	print Dumper @nodes;
	my $node = $tree_to_substitute;

	push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0, operand_visited => 0};

	while (@stack_tree_walk) {

# 		if ($node->{type} eq "variable" and $node->{value} eq $insertion_point) {	# variable to be substitued
# 			$node->%* = $inserted_expression->%*;
# 			pop @stack_tree_walk;
# 			$node = $stack_tree_walk[-1];
# 		}
# 		elsif ($node->{type} eq "binary_op") {	# OPERATOR
		if ($node->{type} eq "binary_op") {		# OPERATOR
			if (not $stack_tree_walk[-1]->{left_visited}) {
				$node = $node->{left};
				$stack_tree_walk[-1]->{left_visited} = 1;
				push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0};
			}
			elsif (not $stack_tree_walk[-1]->{right_visited}) {
				$node = $node->{right};
				$stack_tree_walk[-1]->{right_visited} = 1;
				push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0};
			}
			else {
				pop @stack_tree_walk;
				if (@stack_tree_walk) {
					$node = $stack_tree_walk[-1];
				}
			}
		}
		elsif ($node->{type} eq "unary_op") {	# FUNCTIONS
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
		else {									# NUMBER or VARIABLE
			pop @stack_tree_walk;
			$node = $stack_tree_walk[-1];
		}
	}


}



sub tree_walk_sub {
	my ($node, $sub) = @_;
	$sub->($node);
	if ($node->{type} eq "binary_op") { # node has children
		tree_walk_sub($node->{left}, $sub);
		tree_walk_sub($node->{right}, $sub);
	}
	elsif ($node->{type} eq "unary_op") { # node has children
		tree_walk_sub($node->{operand}, $sub);
	}
}

sub tree_clear_walkmarks {
	tree_walk_sub($_[0], sub { delete $_[0]->%{"left_visited","operand_visited","side"} });
}


# my $tree_pattern = { type => "binary_op", value => "^", capture => { 2 => "right", 3 => "left" } };
# tree_starts_with --> returns [ $idx, \@capture ]
# tree_match       --> returns an array of what returns tree_starts_with
# tree_substitue   --> calls tree_match
#                  --> calls a function that makes a tree walk on $tree_replacement and substitute into it
#                         what has been captured by tree_starts_with for this node index
#                  --> then finally substitute each $tree_replacement at this place

# find_node_path --> identify the parts that are not bijective without modification
# xx             --> see if there are parts that are not bijective at all







1;

