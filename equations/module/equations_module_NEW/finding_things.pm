
package finding_things;
use strict;
use warnings;

# substitute (tree) -> match -> startswith
# substitute (variable) by its value -> contains


use Exporter 'import';
our @EXPORT = qw(
		find_node_path
		find_node_path2
		find_var_path2
		find_nodes
		find_variables
		find_equations_containing_var
		tree_walk
		tree_starts_with
		tree_match
		tree_substitute
		mark_nodes
		put_variable_on_the_left
		set_parent
		simplify_term
		treewalk_lookfor_simplification
		copy_data_structure
);

# our @EXPORT_OK = qw(tree_walk);

use Operations;
# use graph;
use set_operations;
use List::Util qw(uniq any);
use Data::Dumper;
# use dd;

our %precedence;
our %left_associative;
our %right_associative;
our %inverse;
our @var_knowns;
our %var_knowns_values;

# my ($pkg) = caller();
# *precedence        = *$pkg::precedence;
# *inverse           = \${$pkg}{inverse};
# *precedence        = *main::precedence;

*left_associative  = *main::left_associative;
*right_associative = *main::right_associative;
*inverse           = *main::inverse;
*var_knowns        = *main::var_knowns;
*var_knowns_values = *main::var_knowns_values;

##########################
#     FINDING THINGS     #
##########################


# we want to found the path of the variable to isolate in the binary expression tree
# the variable is necessarily a leaf


# 	foreach (grep {$_->{value} eq "^" and $_->{side} eq "right"  } @operations) {

sub find_node_path2 {
	my $eq = shift;
	my $id = shift;

	sub tree_walk_path {
		my $node = shift;
		my $id = shift;
		my @path;
		my $res;

		if ($node->{id} == $id) {
			return 1, @_;
# 			return @_;
		}

		if ($node->{type} eq "binary_op") {
			($res, @path) = tree_walk_path($node->{left}, $id, @_, { $node->%*, side => "left" });
# 			@path = tree_walk_path($node->{left}, $id, @_, { $node->%*, side => "left" });
			if ($res) { return 1, @path }
# 			if (defined $path[0]) { return @path }

			($res, @path) = tree_walk_path($node->{right}, $id, @_, { $node->%*, side => "right" });
# 			@path = tree_walk_path($node->{right}, $id, @_, { $node->%*, side => "right" });
			if ($res) { return 1, @path }
# 			if (defined $path[0]) { return @path }

            return undef;
		}
		elsif ($node->{type} eq "unary_op") {
			($res, @path) = tree_walk_path($node->{operand}, $id, @_, { $node->%*, side => "" });
# 			@path = tree_walk_path($node->{operand}, $id, @_, { $node->%*, side => "" });
			if ($res) { return 1, @path }
# 			if (defined $path[0]) { return @path }
		}
        else {
            return undef;
        }
	}

	foreach my $side ("left_side", "right_side") {
		my ($res, @path) = tree_walk_path($eq->{trees}->{$side}, $id);
# 		my @path = tree_walk_path($eq->{trees}->{$side}, $id);
		if ($res) {
# 		if (defined $path[0]) {
			return $side, @path;
		}
	}
}

sub find_var_path2 {
	my $eq = shift;
	my $var = shift;

	sub tree_walk_path2 {
		my $node = shift;
		my $var = shift;
		my @path;
		my $res;

		if ($node->{type} eq "variable" and $node->{value} eq $var) {
			return 1, @_;
# 			return @_;
		}

        # which key/value pair of $node->%* take ??

		if ($node->{type} eq "binary_op") {
			($res, @path) = tree_walk_path2($node->{left}, $var, @_, { $node->%*, side => "left" });
			if ($res) { return 1, @path }
# 			@path = tree_walk_path2($node->{left}, $var, @_, { $node->%*, side => "left" });
# 			if (defined $path[0]) { return @path }

			($res, @path) = tree_walk_path2($node->{right}, $var, @_, { $node->%*, side => "right" });
			if ($res) { return 1, @path }
# 			@path = tree_walk_path2($node->{right}, $var, @_, { $node->%*, side => "right" });
# 			if (defined $path[0]) { return @path }

            return undef;
		}
		elsif ($node->{type} eq "unary_op") {
			($res, @path) = tree_walk_path2($node->{operand}, $var, @_, { $node->%*, side => "" });
			if ($res) { return 1, @path }
# 			@path = tree_walk_path2($node->{operand}, $var, @_, { $node->%*, side => "" });
# 			if (defined $path[0]) { return @path }
		}
        else {
            return undef;
        }
	}

	foreach my $side ("left_side", "right_side") {
		my ($res, @path) = tree_walk_path2($eq->{trees}->{$side}, $var);
# 		my @path = tree_walk_path2($eq->{trees}->{$side}, $var);
		if ($res) {
# 		if (defined $path[0]) {
			return $side, @path;
		}
	}
}


sub find_node_path {
	my %params = (variable=> 0, node=> 0);
	%params = @_;
	my $equation = $params{equation};
	my $variable = $params{which} if $params{variable};
	my $node_id  = $params{which} if $params{node};
	my @stack_tree_walk;
	my @sides = ("left_side","right_side");
	my $side;

# 	foreach my $node ($equation->{trees}->{left_side}, $equation->{trees}->{right_side}) {
	FOREACH :
	foreach my $node ({$equation->{trees}->{left_side}->%*}, {$equation->{trees}->{right_side}->%*} ) {

		push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0, side => "left", operand_visited => 0};
		$side = shift @sides;

		while (@stack_tree_walk) {

			if ($params{variable}) {
				if ($node->{type} eq "variable" and $node->{value} eq $variable) {	# variable found
					pop @stack_tree_walk; 											# remove variable node
# 					return $side, map { { $_->%{"type", "value", "id"}, exists $_->{side} ? $_->%{side} : () } } @stack_tree_walk;
					last FOREACH;
					# exclude left_visited, left (subtre), right (subtree)
					# node of type unary_op don't have a side value
				}
			}
			elsif ($params{node}) {
				if ($node->{id} == $node_id) {										# node found
					pop @stack_tree_walk; 											# remove node
# 					return $side, map { { $_->%{"type", "value", "id"}, exists $_->{side} ? $_->%{side} : () } } @stack_tree_walk;
					last FOREACH;
					# exclude left_visited, left (subtre), right (subtree)
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
	}
# 	return 0; # variable not found, $operations[0] = 0, which evaluates to false in boolean context
	
	unless (@stack_tree_walk ) {
		# isolate function logic, not required for the logic of find_node_path
		if ($params{variable}) {
			if ($equation->{trees}->{left_side}->{value} eq $params{which}) {
# 				return
			}
			elsif ($equation->{trees}->{right_side}->{value} eq $params{which}) {	# need to change side
# 				put_variable_on_the_left($equation->{trees});
# 				return
			}
			else {
# 				die "variable $params{which} to isolate not found in the equation $equation->{string}\n"
			}
		}
		elsif ($params{node}) {
			if ($equation->{trees}->{left_side}->{id} eq $params{which}) {
# 				return
			}
			elsif ($equation->{trees}->{right_side}->{id} eq $params{which}) {	# need to change side
# 				put_variable_on_the_left($equation->{trees});
# 				return
			}
			else {
# 				die "node $params{which} to isolate not found in the equation $equation->{string}\n"
			}
		}
	}
	return $side, map { { $_->%{"type", "value", "id"}, exists $_->{side} ? $_->%{side} : () } } @stack_tree_walk;
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

sub tree_starts_with {
	my ($tree_to_match, $tree_pattern) = @_;

	sub compare_two_trees {
		my ($node_to_match, $node_pattern) = (shift, shift);
		my @capture = @_;
		my $res;
		foreach (grep { not ref $node_pattern->{$_} } keys $node_pattern->%*) {
			if ($node_to_match->{$_} ne $node_pattern->{$_}) {
				return 0
			}
		}
		if (exists $node_pattern->{capture}) {
			while ( my ($idx, $key) = each $node_pattern->{capture}->%* ) {
				if (exists $node_to_match->{$key}) {
					$capture[$idx] = $node_to_match->{$key}
				}
			}
		}

		if ($node_to_match->{type} eq "binary_op") {
			if (exists $node_pattern->{left}) {
				($res, @capture)=compare_two_trees($node_to_match->{left}, $node_pattern->{left}, @capture);
				if (not $res) {
					return 0
				}
			}

			if (exists $node_pattern->{right}) {
				($res, @capture)=compare_two_trees($node_to_match->{right}, $node_pattern->{right}, @capture);
				if (not $res) {
					return 0
				}
			}
		}
		elsif ($node_to_match->{type} eq "unary_op") {
			if (exists $node_pattern->{operand}) {
				($res, @capture)=compare_two_trees($node_to_match->{operand}, $node_pattern->{operand}, @capture);
				if (not $res) {
					return 0
				}
			}
		}
		return 1, @capture;
	}
	return compare_two_trees($tree_to_match, $tree_pattern);
}

sub tree_match {
	my ($tree, $tree_pattern) = @_;
	my @stack_tree_walk;
	my $node = $tree;
	my @node_id;
	my @capture;
	my $res;
	push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0, operand_visited => 0};

	while(@stack_tree_walk) {

		if ($node->{type} eq "binary_op") {				# operator
			if (not $stack_tree_walk[-1]->{left_visited}) {

				($res, @capture) = tree_starts_with($node, $tree_pattern);
				if ($res) {
					if (@capture) {
						push @node_id, { id => $node->{id}, capture => [@capture] };
					}
					else {
						push @node_id, $node->{id};
					}
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

				($res, @capture) = tree_starts_with($node, $tree_pattern);
				if ($res) {
					if (@capture) {
						push @node_id, { id => $node->{id}, capture => [@capture] };
					}
					else {
						push @node_id, $node->{id};
					}
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

			($res, @capture) = tree_starts_with($node, $tree_pattern);
			if ($res) {
				if (@capture) {
					push @node_id, { id => $node->{id}, capture => [@capture] };
				}
				else {
					push @node_id, $node->{id};
				}
			}

			pop @stack_tree_walk;
			$node = $stack_tree_walk[-1];
		}
	}
	return @node_id;
}

# output of tree_match

# array of (multiple nodes match)
# hashes --> id => node_id, capture => [ subtrees ]

sub tree_substitute {
	my ($tree_to_substitute, $tree_pattern, $tree_to_replace) = @_;
	my @stack_tree_walk;
	my $node = $tree_to_substitute;
	my %replacements;
	my $new_node;

	sub add_subtrees {
		my @captures = @_;
		return sub {
			my $node = shift;
			my ($idx,$key);
			if (exists $node->{capture}) {
				while (($idx, $key) = each $node->{capture}->%*) {
					$node->{$key} = $captures[$idx];
				}
				delete $node->{capture};
			}
		}
	}

	foreach (tree_match($tree_to_substitute, $tree_pattern)) {
		$new_node = copy_data_structure($tree_to_replace);
		tree_walk($new_node, add_subtrees($_->{capture}->@*) );
		$replacements{$_->{id}} = $new_node;
	}

	push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0, operand_visited => 0};

	while (@stack_tree_walk) {

		foreach (keys %replacements) {
			if (exists $node->{id}) {
				if ($node->{id} == $_ ) {
					#$node = $replacements{$_}
					$node->%* = $replacements{$_}->%*
				}
				delete $replacements{$_};
			}
		}
# 		print "="x40;
# 		print $node->{value};

		if ($node->{type} eq "binary_op") {		# OPERATOR
			if (not $stack_tree_walk[-1]->{left_visited}) {
				$node = $node->{left};
				$stack_tree_walk[-1]->{left_visited} = 1;
				push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0};
# 				push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0, operand_visited=> 0};
			}
			elsif (not $stack_tree_walk[-1]->{right_visited}) {
				$node = $node->{right};
				$stack_tree_walk[-1]->{right_visited} = 1;
				push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0};
# 				push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0, operand_visited => 0};
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

# 				print ref $node eq "" ? "scalar" : "reference";
# 				print $node->%*;

				push @stack_tree_walk, {$node->%*, operand_visited => 0};
# 				push @stack_tree_walk, {$node->%*, operand_visited => 0, left_visited=>0, right_visited=>0};
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



sub tree_walk {
	my ($node, $sub) = @_;
	$sub->($node);
# 	if (exists $node->{type}) {
		if ($node->{type} eq "binary_op") { # node has children
			tree_walk($node->{left}, $sub);
			tree_walk($node->{right}, $sub);
		}
		elsif ($node->{type} eq "unary_op") { # node has children
			tree_walk($node->{operand}, $sub);
		}
# 	}
# 	else { print Dumper $node  }
}

sub tree_clear_walkmarks {
	tree_walk($_[0], sub { delete $_[0]->%{"left_visited","operand_visited","side"} });
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



sub mark_nodes {	
	my $sub = do { my $id=0; sub { $_[0]->{id} = $id; $id++ } };
 	tree_walk($_[0]->{trees}->{left_side}, $sub );
 	tree_walk($_[0]->{trees}->{right_side}, $sub );
}


sub put_variable_on_the_left {
	my $equation = shift;
	my $temp_expression_storage;
	if ($equation->{right_side}->{type} eq "variable"
	 or $equation->{right_side}->{type} eq "number") {

		$temp_expression_storage = $equation->{right_side};
		$equation->{right_side} = $equation->{left_side};
		$equation->{left_side} = $temp_expression_storage;
	}
	elsif ($equation->{left_side}->{type} eq "variable"
	    or $equation->{left_side}->{type} eq "number") {
		return;
	}
	else {
		die "isn't in a form where one variable is alone on of the side of =\n";
	}
}


sub set_parent {
	my $node = shift;
	my $parent = shift;

	if (defined $parent) {	# every node except top of the tree
		$node->{parent} = $parent;
	}
	elsif (exists $node->{parent}) {	# top of the tree, no parent
		delete $node->{parent};
	}

	if ($node->{type} eq "binary_op") {
		set_parent($node->{left}, $node);
		set_parent($node->{right}, $node);
	}
	elsif ($node->{type} eq "unary_op") {
		set_parent($node->{operand}, $node);
	}
}


sub simplify_term {
	my $expression = shift;

	sub something_to_simplify {
		my $expression = shift;

		sub treewalk_lookfor_simplification {
			my $tree = shift;


# 			SIMPLIFY

# 			 0 * something
# 			 1 * something

# 			 something / 1
# 			 0 / something

# 			 something ^ 0
# 			 something ^ 1
# 			 0 ^ something
# 			 1 ^ something

# 			 0 + something
# 			 0 - something
# 			- - /  - + - / etc...

			if ($tree->{type} eq "binary_op") {

				if ($tree->{value} eq "+" or $tree->{value} eq "-") {

					if ($tree->{left}->{type} eq "number") {
						# 0+x or 0-x
						if ($tree->{left}->{value} == 0) {
							return 1
						}
					}
					elsif ($tree->{left}->{type} eq "binary_op") {
						if (treewalk_lookfor_simplification($tree->{left})) {
							return 1
						}
					}

					if ($tree->{right}->{type} eq "number") {
						# x+0 or x-0
						if ($tree->{right}->{value} == 0) {
							return 1
						}
					}
					elsif ($tree->{right}->{type} eq "binary_op") {
						if (treewalk_lookfor_simplification($tree->{right})) {
							return 1
						}
					}
				}
				elsif ($tree->{value} eq "*") {

					if ($tree->{left}->{type} eq "number") {
						# 0*x or 1*x
						if ($tree->{left}->{value} == 0 or $tree->{left}->{value} == 1 ) {
							return 1
						}
					}
					elsif ($tree->{left}->{type} eq "binary_op") {
						if (treewalk_lookfor_simplification($tree->{left})) {
							return 1
						}
					}

					if ($tree->{right}->{type} eq "number") {

						# x*0 or x*1
						if ($tree->{right}->{value} == 0 or $tree->{right}->{value} == 1 ) {
							return 1
						}
					}
					elsif ($tree->{right}->{type} eq "binary_op") {
						if (treewalk_lookfor_simplification($tree->{right})) {
							return 1
						}
					}
				}
				elsif ($tree->{value} eq "/") {
					if ($tree->{left}->{type} eq "number") {
						# 0/x
						if ($tree->{left}->{value} == 0) {
							return 1
						}
					}
					elsif ($tree->{left}->{type} eq "binary_op") {
						if (treewalk_lookfor_simplification($tree->{left})) {
							return 1
						}
					}

					if ($tree->{right}->{type} eq "number") {
						# x/1
						if ($tree->{right}->{value} == 1) {
							return 1
						}
					}
					elsif ($tree->{right}->{type} eq "binary_op") {
						if (treewalk_lookfor_simplification($tree->{right})) {
							return 1
						}
					}
				}
				elsif ($tree->{value} eq "^") {

					if ($tree->{left}->{type} eq "number") {
						# 0^x or 1^x
						if ($tree->{left}->{value} == 0 or $tree->{left}->{value} == 1) {
							return 1
						}
					}
					elsif ($tree->{right}->{type} eq "binary_op") {
						if (treewalk_lookfor_simplification($tree->{right})) {
							return 1
						}
					}

					if ($tree->{right}->{type} eq "number") {
						# x^0 or x^1
						if ($tree->{right}->{value} == 0 or $tree->{right}->{value} == 1) {
							return 1
						}
					}
					elsif ($tree->{right}->{type} eq "binary_op") {
						if (treewalk_lookfor_simplification($tree->{left})) {
							return 1
						}
					}
				}
			}
			return 0
		}

		if (treewalk_lookfor_simplification($expression)) {
			return 1
		}
		else {
			return 0
		}
	}

	sub do_simplify {
		my $tree = shift;

		if ($tree->{type} eq "binary_op") {

			if ($tree->{value} eq "+") {

				if ($tree->{left}->{type} eq "number") {
					# 0+x or 0-x
					if ($tree->{left}->{value} == 0) {
						$tree = { $tree->{right}->%* };
					}
				}
				elsif ($tree->{left}->{type} eq "binary_op") {
					do_simplify($tree->{left});
				}

				if ($tree->{right}->{type} eq "number") {
					# x+0 or x-0
					if ($tree->{right}->{value} == 0) {
						$tree = { $tree->{left}->%* };
					}
				}
				elsif ($tree->{right}->{type} eq "binary_op") {
					do_simplify($tree->{right});
				}
			}
			elsif ($tree->{value} eq "-") {

				if ($tree->{left}->{type} eq "number") {
					# 0-x
					if ($tree->{left}->{value} == 0) {
# 						$tree
						$tree = { type => "unary_op", value => "-", operand => $tree->{right} };
					}
				}
				elsif ($tree->{left}->{type} eq "binary_op") {
					do_simplify($tree->{left});
				}

				if ($tree->{right}->{type} eq "number") {
					# x-0
					if ($tree->{right}->{value} == 0) {
						$tree = { $tree->{left}->%* };
					}
				}
				elsif ($tree->{right}->{type} eq "binary_op") {
					do_simplify($tree->{right});
				}
			}
			elsif ($tree->{value} eq "*") {

				if ($tree->{left}->{type} eq "number") {
					# 0*x or 1*x
					if ($tree->{left}->{value} == 0) {
					}
					elsif ($tree->{left}->{value} == 1 ) {
					}
				}
				elsif ($tree->{left}->{type} eq "binary_op") {
					do_simplify($tree->{left});
				}

				if ($tree->{right}->{type} eq "number") {

					# x*0 or x*1
					if ($tree->{right}->{value} == 0) {
						$tree = { type => "number", value => 0 };
					}
					elsif ($tree->{right}->{value} == 1 ) {
						$tree = { $tree->{left}->%* };
					}
				}
				elsif ($tree->{right}->{type} eq "binary_op") {
					do_simplify($tree->{right});
				}
			}
			elsif ($tree->{value} eq "/") {
				if ($tree->{left}->{type} eq "number") {
					# 0/x
					if ($tree->{left}->{value} == 0) {
						$tree = {type => "number", value => 0}
					}
				}
				elsif ($tree->{left}->{type} eq "binary_op") {
					do_simplify($tree->{left});
				}

				if ($tree->{right}->{type} eq "number") {
					# x/1
					if ($tree->{right}->{value} == 1) {
						$tree = { $tree->{left}->%* };
					}
				}
				elsif ($tree->{right}->{type} eq "binary_op") {
					do_simplify($tree->{right});
				}
			}
			elsif ($tree->{value} eq "^") {

				if ($tree->{left}->{type} eq "number") {
					# 0^x or 1^x
					if ($tree->{left}->{value} == 0) {
						# unless x =0
						$tree = {type => "number", value => 0}
					}
					elsif ($tree->{left}->{value} == 1) {
						$tree = {type => "number", value => 1}
					}
				}
				elsif ($tree->{right}->{type} eq "binary_op") {
					do_simplify($tree->{right});
				}

				if ($tree->{right}->{type} eq "number") {
					# x^0 or x^1
					if ($tree->{right}->{value} == 0) {
						$tree = {type => "number", value => 0}
					}
					elsif ($tree->{right}->{value} == 1) {
						$tree = { $tree->{left}->%* }
					}
				}
				elsif ($tree->{right}->{type} eq "binary_op") {
					do_simplify($tree->{left});
				}
			}
		}
	}

# 	while (something_to_simplify($expression)) {
		do_simplify($expression)
# 	}

}




1;

