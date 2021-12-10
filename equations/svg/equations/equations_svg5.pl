#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

# DATA FLOW
# parse arguments -> tokenize = infix -> infix_to_postfix -> postfix_to_tree -> make_equation
# find_node_path -> isolate -> find_nodes -> substitute

# CALL STACK
# -> make_equation -> tokenize, infix_to_postfix, postfix_to_tree
# -> find_nodes
# -> set_intersection
# -> set_difference
# -> powerset
# -> ...
# -> tree_to_infix

# BOOTSTRAP
# make_equation -> find_variable_path -> isolate ---> make_equation_graph
# each equation is not longer represented by 2 trees but by 1 graph
# make one graph that links all the equations

# GRAPH   FUNCTION : NODE --> NODE
# make_equation, walk the tree and assign an indentifier to each node encountered (variables, numbers and even operators)
# walk the tree another time and record edges --> edge (between 2 nodes) is the variable on top of the stack and the one just below
# root node connected to the variable that is on the other side (if there is an isolated variable on the other side and not
# and expression) direction = from node at stack ($#stack - 1) towards node at ($#stack)
# foreach variable of the equation, isolate first found, and do what was explained. add the edge to the same data structure
# data structure --> %equation_graph=(node1 => [], node2 => [], node3 => [], etc..)
# do this foreach equation
# %overall_equations_graph -> foreach node, concat arrays and make the elements unique

# GRAPH
# is there more than one "island" ?
# can a given variable (the wanted variable) can be expressed in function of a given set of variable (known variables) ?
# if it can't, what unknown variables should be known for it to work ? other type of "can't work" ?
# algorithm to walk the graph ? Depth First Search ? Breadth First Search ?
# extract a directed subgraph, a binary expression tree, from the overall graph ? then convert it to postfix and evaluate that

# if a variable is known, don't substitute it in the overall graph


# find_node_path
#	returns chain (array) of nodes from root to node searched for, excluding the node itself
#	returns chain (array) of nodes from root to first variable searched for, excluding the variable itself

# find_nodes
#	returns array of variables
#	returns array of the nodes id and their type


# substitute # substitutes $inserted_equation (expression) INTO $master_equation


$/=undef;
my $input;
my @equations;
my @var_knowns;
#our @var_knowns;		# for recursive_solve ??
my %var_knowns_values;
my @var_wants;

if (@ARGV) {
	if (-e $ARGV[0]) { $input = <ARGV>  }
	else             { $input = $ARGV[0]}
}
elsif (not -t STDIN) { $input = <STDIN> }
else                 {exit}

my @assertions = split /,/, $input;
tr/ //d for @assertions;

while(my $assertion = shift @assertions) {

	if($assertion =~							# KNOWNS
			m/^([a-zA-Z][a-zA-Z0-9]*)=[0-9]+\.?[0-9]*$
			|^[0-9]+\.?[0-9]*=([a-zA-Z][a-zA-Z0-9]*)$/x
		) 	{push @var_knowns, $+}

	elsif($assertion =~							# KNOWNS VALUES
			m/^(?<variable>[a-zA-Z][a-zA-Z0-9]*)=(?<value>[0-9]+\.?[0-9]*)$
			|^(?<value>[0-9]+\.?[0-9]*)=(?<variable>[a-zA-Z][a-zA-Z0-9]*)$/x
		) 	{$var_knowns_values{$+{variable}} = $+{value}}

	elsif($assertion =~ m/=/)
			{push @equations, $assertion}		# EQUATIONS
	else	{push @var_wants, $assertion}		# WANTS
}

@var_knowns = sort @var_knowns;
@var_wants = sort @var_wants;

$,="\n";
$\="\n";

my @tokens;

sub tokenize {
	my $expression = shift;
	my @tokens;
	my $end = 0;
	while(not $end){
		if   ($expression =~ m/\G /gc)                     { 1; }
		elsif($expression =~ m/\G(\d+)/gc)                 { push @tokens, $1  }
		elsif($expression =~ m/\G([a-zA-Z][a-zA-Z0-9]*)/gc){ push @tokens, $1  }

		elsif($expression =~ m/\G\+/gc)                    { push @tokens, "+" }
		elsif($expression =~ m/\G\-/gc)                    { push @tokens, "-" }
		elsif($expression =~ m/\G\*/gc)                    { push @tokens, "*" }
		elsif($expression =~ m/\G\//gc)                    { push @tokens, "/" }

		elsif($expression =~ m/\G\(/gc)                    { push @tokens, "(" }
		elsif($expression =~ m/\G\)/gc)                    { push @tokens, ")" }

		else {$end = 1}
	}
	return @tokens;
}

# Shunting-Yard algorithm
# https://en.wikipedia.org/wiki/Shunting-yard_algorithm (complete algorithm here)
# https://www.youtube.com/watch?v=Wz85Hiwi5MY           (not complete algorithm)
sub infix_to_postfix {
	my @stack;
	my @queue;
	my $token;
	my $op;
	my %precedence = ("(" => 2, ")" => 2, "*" => 1, "/" => 1, "+" => 0, "-" => 0);
	my %associativity = ("*" => "both?", "/" => "", "+" => "both?", "-" => "");
	foreach $token (@_){
		if ($token =~ /\d|[a-zA-Z]/) {		# NUMBER or VARIABLE
			push @queue, $token;
		}
#		elsif ($token is a function) {		# FUNCTION
#			push @stack, $token;
#		}
		elsif ($token =~ m|[-+*/]|) {		# OPERATOR
#			while (($#stack >= 0)
#				  and (( $precedence{$token} < $precedence{$stack[-1]} )
#					  or (  $precedence{$token} == $precedence{$stack[-1]} and $associativity{$token} eq "left"  ))
#				  and ( $stack[-1] ne "("  )) {
			while (($#stack >= 0) 
				  and ( $precedence{$token} < $precedence{$stack[-1]} )
				  and ( $stack[-1] ne "(" ) ) {

				push @queue, pop @stack;
			}
			push @stack, $token;
		}
		elsif ( $token eq "(" ) {			# OPENING PARENTHESIS
			push @stack, $token;
		}
		elsif ( $token eq ")" ) {			# CLOSING PARENTHESIS
			while ($stack[-1] ne "(") {
				push @queue, pop @stack;
			}
			#/* If the stack runs out without finding a left parenthesis, then there are mismatched parentheses. */
			if ( $stack[-1] eq "(" ) {
				pop @stack;					# operator
			}
#			if ( $stack[-1] is a function ) {
#				push @queue, pop @stack;	# function
#			}
		}
	} # end foreach
	while ($op = pop @stack){
		push @queue, $op;
	}
	return @queue;
}


# postfix stack evaluator
# https://www.youtube.com/watch?v=bebqXO8H4eA
sub reverse_polish_calculator {
	my @queue = @_;
	my @stack;
	my ($first, $second);
	my $symbol;

	while ($symbol = shift @queue) {
		if ($symbol =~ m/\d/){		# NUMBER
			push @stack, $symbol;
		}
		else {						# OPERATOR
			$second = pop @stack;
			$first  = pop @stack;
			if    ($symbol eq "+") { push @stack, $first + $second }
			elsif ($symbol eq "-") { push @stack, $first - $second }
			elsif ($symbol eq "*") { push @stack, $first * $second }
			elsif ($symbol eq "/") { push @stack, $first / $second }
		}
	}
	return pop @stack;
}

# https://en.wikipedia.org/wiki/Binary_expression_tree#Construction_of_an_expression_tree
sub postfix_to_tree {
	my @stack;
	my $left;
	my $right;
	while (my $symbol = shift @_) {
		if ($symbol =~ m/\d/) {
			push @stack, {type=> "number", value=> $symbol};
		}
		elsif ($symbol =~ m/[a-zA-Z]/) {
			push @stack, {type=> "variable", value=> $symbol};
		}
		else {
			$right = pop @stack;
			$left  = pop @stack;
			push @stack, {type=> "operator", value=> $symbol, left=> $left, right=> $right};
		}
	}
	return pop @stack;
}


sub make_equation {
	my $input_equation = shift;
	my ($left_expression, $right_expression) = split /=/, $input_equation;

	my @left_infix   = tokenize($left_expression);
	my @left_postfix = infix_to_postfix(@left_infix);
	my $left_tree    = postfix_to_tree(@left_postfix);

	my @right_infix   = tokenize($right_expression);
	my @right_postfix = infix_to_postfix(@right_infix);
	my $right_tree    = postfix_to_tree(@right_postfix);

	return {left_side => $left_tree, right_side=> $right_tree};
}


# variable to isolate

# on right side of multiply -> divide other side of equation by left subtree
# on left  side of multiply -> divide other side of equation by right subtree
#     (variable do not change of side in either case)

# on right side of divide   -> multiply other side of eqution by right subtree (contains variable to isolate)
#                              (variable change of side)
# on left  side of divide  -> multiply other side of eqution by right subtree

# on right side of addition -> substract other side of eqution by left subtree
# on left  side of addition -> substract other side of eqution by right subtree
#     (variable do not change of side in either case)

# on right side of substraction -> addition other side of eqution by right subtree (contains variable to isolate)
#                                   (variable change of side)
# on left  side of substraction -> addition other side of eqution by right subtree


sub isolate {
	my %params = (variable=> 0, node=> 0);
	%params = @_;
	my $equation = $params{equation}->{trees};
	my $variable;
	my $node;
	my @operations;
	my $operation;
	our $variable_op_side;
	our $equation_side;

	if ($params{variable}) {
		$variable = $params{which};
		@operations = find_node_path(variable=> 1, which=> $variable, expression=> $equation->{left_side});
		$equation_side = "left_side";

		if ( not $operations[0]) {
			if($equation->{left_side}->{value} eq $variable) {
				return $equation;
			}
			else {
			# variable not found in equation's left side
				@operations = find_node_path(variable=> 1, which=> $variable, expression=> $equation->{right_side});
				$equation_side = "right_side";
			}
		}
		if ( not $operations[0]) {
			if($equation->{right_side}->{value} eq $variable) {
				return $equation;
			}
			else {
			# variable not found in equation's right side
				die "variable $variable to isolate not found in the equation $params{equation}->{string}\n";
			}
		}
	}
	elsif ($params{node}) {
		$node = $params{which};
		@operations = find_node_path(node=> 1, which=> $node, expression=> $equation->{left_side});
		$equation_side = "left_side";

		if ( not $operations[0]) {
			if($equation->{left_side}->{id} == $node) {
				return $equation;
			}
			else {
			# variable not found in equation's left side
				@operations = find_node_path(node=> 1, which=> $node, expression=> $equation->{right_side});
				$equation_side = "right_side";
			}
		}
		if ( not $operations[0]) {
			if($equation->{right_side}->{id} == $node) {
				return $equation;
			}
			else {
			# variable not found in equation's right side
				die "node $node to isolate not found in the equation $params{equation}->{string}\n";
			}
		}
	}



	sub other_equation_side { return "right_side" if $equation_side eq "left_side"; return "left_side" }
	sub other_variable_op_side { return "right" if $variable_op_side eq "left"; return "left" }

	while ($operation = shift @operations) {
		$variable_op_side = $operation->{side};

		if ($operation->{value} eq "*") {
			$equation->{other_equation_side()} = { type=> "operator", value=> "/", id=> $operation->{id},
                                                       left=> $equation->{other_equation_side()},
                                                      right=> $equation->{$equation_side}->{other_variable_op_side()} };
			$equation->{$equation_side} = $equation->{$equation_side}->{$variable_op_side};
		}
		elsif ($operation->{value} eq "/") {
			$equation->{other_equation_side()} = { type=> "operator", value=> "*", id=> $operation->{id},
                                                       left=> $equation->{other_equation_side()},
                                                      right=> $equation->{$equation_side}->{right} };
			$equation->{$equation_side} = $equation->{$equation_side}->{left};
			if ($variable_op_side eq "right") {
				$equation_side = other_equation_side();
				unshift @operations, {type=> "operator", value=> "*", side=> "right", id=> $operation->{id} };
			}
		}
		elsif ($operation->{value} eq "+") {
			$equation->{other_equation_side()} = { type=> "operator", value=> "-", id=> $operation->{id},
                                                       left=> $equation->{other_equation_side()},
                                                      right=> $equation->{$equation_side}->{other_variable_op_side()} };
			$equation->{$equation_side} = $equation->{$equation_side}->{$variable_op_side};
		}
		elsif ($operation->{value} eq "-") {
			$equation->{other_equation_side()} = { type=> "operator", value=> "+", id=> $operation->{id},
                                                       left=> $equation->{other_equation_side()},
                                                      right=> $equation->{$equation_side}->{right} };
			$equation->{$equation_side} = $equation->{$equation_side}->{left};
			if ($variable_op_side eq "right") {
				$equation_side = other_equation_side();
				unshift @operations, {type=> "operator", value=> "+", side=> "right", id=> $operation->{id} };
			}
		}
	}
	isolate_variable_on_left($equation);
}

# in-order tree traversal, to obtain infix expression
sub tree_to_infix {
	my $expression = shift;
	my $node = $expression;
	if ($node->{type} eq "operator") {
		print "(";
		tree_to_infix($node->{left});
		print $node->{value};
		tree_to_infix($node->{right});
		print ")";
	}
	else {
		print $node->{value};
	}
}


########################
#     TREE WALKING     #
########################


# we want to found the path of the variable to isolate in the binary expression tree
# the variable is necessarily a leaf

sub find_node_path {
	my %params = (variable=> 0, node=> 0);
	%params = @_;
	my $expression = $params{expression};
	my $equation_debug = $params{equation_debug}->{string};
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
	my %params = (variables=> 0, nodes=> 0);
	%params = @_;
	my $equation = $params{equation};
	my $left_expression = $equation->{left_side};
	my $right_expression = $equation->{right_side};
	my @stack_tree_walk;
	my @nodes;
	my %nodes;
	my $node;

	foreach my $expression ($left_expression, $right_expression) {
		@stack_tree_walk = ();
		$node = $expression; # start at root node
		push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};

		while(@stack_tree_walk) {

			if ($params{variables}) {
				if ($node->{type} eq "variable") {			# variable
					push @nodes, $node->{value};
					pop @stack_tree_walk;
					$node = $stack_tree_walk[-1];
					next;
				}
			}
			elsif ($params{nodes}) {						# each node
					$nodes{$node->{id}} = $node->{type};
			}

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
	return sort keys %{ {map { $_ => 1 } @nodes} } if $params{variables};
	return %nodes                                  if $params{nodes};
}

sub substitute { # substitute $inserted_equation INTO $master_equation
	my ($inserted_equation, $master_equation) = @_;
	my $inserted_expression = $inserted_equation->{right_side};
	my $insertion_point     = $inserted_equation->{left_side}->{value};
	my $master_expression   = $master_equation->{trees}->{right_side};
	my @stack_tree_walk;
	my $node = $master_expression;
	push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};

	while(@stack_tree_walk) {

		if ($node->{type} eq "variable" and $node->{value} eq $insertion_point) {	# variable to be substitued
			$node->%* = $inserted_expression->%*;
			pop @stack_tree_walk;
			$node = $stack_tree_walk[-1];
		}
		elsif ($node->{type} eq "operator") {
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
		else {
			pop @stack_tree_walk;
			$node = $stack_tree_walk[-1];
		}
	}
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

			if ($node->{type} eq "operator") {			# interior node
				
				if (not $stack_tree_walk[-1]->{left_visited}) {
					$stack_tree_walk[-1]->{left_visited} = 1;
					$node = $node->{left};
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
		unless grep {/$right_expression->{id}/}
			$equation->{graph}->{$left_expression->{id}}->@*;

	push $equation->{graph}->{$right_expression->{id}}->@*,
			$left_expression->{id}
		unless grep {/$left_expression->{id}/}
			$equation->{graph}->{$right_expression->{id}}->@*;
	
	foreach my $expression ($left_expression, $right_expression) {
		@stack_tree_walk = ();
		$node = $expression;
		push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
		while(@stack_tree_walk) {

			if (@stack_tree_walk >= 2) {
				push $equation->{graph}->{$stack_tree_walk[-2]->{id}}->@*,
						$stack_tree_walk[-1]->{id}
					unless grep {/$stack_tree_walk[-1]->{id}/}
						$equation->{graph}->{$stack_tree_walk[-2]->{id}}->@*;
			}

			if ($node->{type} eq "operator") {			# interior node
				
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
					$node = $stack_tree_walk[-1];
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


########################
#    SET OPERATIONS    #
########################

sub set_intersection {
	my ($array_a, $array_b) = @_;
	my @array_c;
	foreach my $var ($array_a->@*) {
		push @array_c, $var if grep /$var/, $array_b->@*;
	}
	return sort @array_c;
}

sub set_difference {	# array_a minus array_b
	my ($array_a, $array_b) = @_;
	my @array_c;
	foreach my $var ($array_a->@*) {
		push @array_c, $var unless grep /$var/, $array_b->@*;
	}
	return sort @array_c;
}

sub set_union {
	my ($array_a, $array_b) = @_;
	return sort keys %{{ map {$_ => 1} $array_a->@*, $array_b->@* }};
}

sub set_equality {
	my ($array_a, $array_b) = @_;
	if ($array_a->$#* != $array_b->$#*) {
		return 0;
	}
	for (my $i=0; $i <= $array_a->$#*; $i++) {
		if ($array_a->[$i] ne $array_b->[$i]) {
			return 0;
		}
	}
	return 1;
}
  
sub set_inclusion {		# is array_a included in array_b
	my ($array_a, $array_b) = @_;
	if (set_equality($array_a, [set_intersection($array_a, $array_b)]))
	{ return 1 }
	else
	{ return 0 }
}

sub powerset {						# set of all subsets of a set
	my @set = @_;
	my $set_size = @set;
	my @powerset;
	my $pow_set_size = 2 ** $set_size;
	my $counter;
	my $j;
	my @subset;
  
	# skip $counter=0 to skip empty set
	for($counter = 1; $counter < $pow_set_size; $counter++) { 
		@subset = ();
		for($j = 0; $j < $set_size; $j++) { 
			push @subset, $set[$j] if $counter & (1 << $j);
		} 
		push @powerset, [ @subset ];
	} 
	return @powerset;
} 

sub missing_information { }

sub set_of_equations_with_enough_information {
#make_powerset of set of equations tupples --> among this set, find the sets of equations that contain enough information
#together for solving the system of equations

#the union of all the equations ' sets of variable minus the wanted variable, must be equal to the union of all the
#equations'sets of variables that are known

#if not enough information, find the set of minimun set of variables that are needed to solve the system of equations

}

sub isolate_variable_on_left {
	my $equation = shift;
	my $temp_expression_storage;
	
	if ($equation->{right_side}->{type} eq "variable") {
		$temp_expression_storage = $equation->{right_side};
		$equation->{right_side} = $equation->{left_side};
		$equation->{left_side} = $temp_expression_storage;
	}
	elsif ($equation->{left_side}->{type} eq "variable") {
		return;
	}
	else {
		die "equation isn't in a form where one variable is alone on of the side of =\n";
	}
}


#########################
#    END SUBROUTINES    #
#########################

########################
#     MAIN PROGRAM     #
########################

my @equations_structures;
#our @equations_structures;		# for recursive_solve ???
my @wants;
my $var;
my $master_equation;

foreach (@equations) {
	push @equations_structures, { string=> $_, trees=> make_equation($_) }
}
foreach (@equations_structures) {
	$_->{variables}->@* = find_nodes(variables=> 1, equation=> $_->{trees});
}
for (my $i=0; $i < @equations_structures; $i++ ) {
	$_ = $equations_structures[$i];
	$_->{knowns}->@* = set_intersection( $_->{variables}, \@var_knowns);
	$_->{wants}->@*  = set_intersection( $_->{variables}, \@var_wants);
#	if ($_->{wants}->@*) {
#		$master_equation = $equations_structures[$i]; # first equation encountered containing wanted variable
#		splice @equations_structures, $i, 1;
#	 }
}
foreach (@equations_structures) {
	$_->{unknowns}->@* = set_difference( $_->{variables}, \@var_knowns);
}

$,="";
$\="\n";

#foreach (@equations_structures, $master_equation) {
#foreach (@equations_structures) {
#	
#	print "EQUATION\t",  $_->{string};
#	print "VARIABLES\t", $_->{variables}->@*;
#	print "WANTS\t\t",   $_->{wants}->@*;
#	print "KNOWNS\t\t",  $_->{knowns}->@*;
#	print "UNKNOWNS\t",  $_->{unknowns}->@*;
#	print "";
#}

$,="\n";

foreach (@equations_structures) {
	mark_nodes($_);
	make_graph($_);
	$_->{nodes}->%* = find_nodes(nodes=> 1, equation=> $_->{trees});
# 	print Dumper $_->{trees};
	
# 	print Dumper $_->{graph};
# 	print Dumper $_->{nodes};
# 	print Dumper $_;
}


foreach my $eq (@equations_structures) {
	# foreach node that is a variable (necessary in case a variable appears more than once)
	foreach my $node_id (grep {$eq->{nodes}->{$_} eq "variable"} keys $eq->{nodes}->%*) {
		isolate(node=> 1, which=> $node_id, equation=> $eq);
		make_graph($eq);
#		$\="";
#		tree_to_infix($eq->{trees}->{left_side});
#		print "=";
#		tree_to_infix($eq->{trees}->{right_side});
#		print "\n";
	}
}




#__END__

sub find_equations_containing_var {
	my ($variable, @set_of_equations) = @_;
	my @set;
	foreach my $eq (@set_of_equations) {
		push @set, $eq
			if grep {/$variable/} $eq->{variables}->@*;
	}
	return @set;
}


sub recursive_solve {
	my ($wanted_var, @bag_of_equations) = @_;
	my @reduced_bag_of_equations;
	my $solve_tree;
	my $temp_solve_tree;
	my @in_function_of_vars;
	my $var;
	my $variable_value
	EQUATION:
	foreach $eq (find_equations_containing_var($wanted_var, @bag_of_equations) {

		@reduced_bag_of_equations = set_difference(\@bag_of_equations, [$eq]);
		isolate(node=> 1, which=> $wanted_var, equation=> $eq);                       # what if variable appears multiple times ??
		$solve_tree = $eq;
		@in_function_of_vars = set_difference([$eq->{variables}->@*], [$wanted_var]); # what if variable appears multiple times ??

		if (set_inclusion(\@in_function_of_vars, \@var_knowns )) {

			foreach $var (@in_function_of_vars) {
				%var_knowns_values
				$variable_value = {left_side=> {type=> "variable", value=> $var },
								  right_side=> {type=> "number", value=> $var_knowns_values{$var} } };
				substitute($variable_value, $solve_tree);
			}
			return $solve_tree;			# recursive substitution successful
		}
		else {
			foreach $var ($eq->{unknowns}->@*) {
			
				$temp_solve_tree = recursive_solve($var, @reduced_bag_of_equations);
				if ($temp_solve_tree == 0) {next EQUATION}
				substitute($temp_solve_tree,  $solve_tree);
			}
			return $solve_tree;			# recursive substitution successful
		}
	}
	return 0;							# recursive substitution unsuccessful, every starting points tried
}


my ($wanted_var) = @var_wants;
my $solve_tree = recursive_solve($wanted_var, @equations_structures);
if ($solve_tree == 0) { die "can not solve system of equations\n"}

my @postfix = tree_to_postfix($solve_tree);
my $result = reverse_polish_calculator(@postfix);
print "$wanted_var = $result";

my $infix = tree_to_infix($solve_tree);
my $result = eval($infix);
print "$wanted_var = $result";



__END__

my $subset;
my $equation;
my @union_variables;
my @union_knowns;
my $enough_information_to_solve_subset = 0;

# FIRST) doesn't take into account the variable that are unknown but that can be substituted by known variables
# graph ?

# SECOND) is there variables that can't be isolated ? (case where a variable appears more than once and it is 
# not possible to have these variables merged in one, which is alone in)

# THIRD) when all thr previous are set, is there orders of substitutions that don't work ?
# or non-unique isolation of variables in a particular equation that doesn't work but at least one other case does ?

# FOUR) how to know if a variable can not be isolated ?
# ==> oriented graph of which variables can be expressed in which other
# ==> a variable cannot be isolated if ... ?

# ORIENTD GRAPH CONSTRUCTION
# ==> isolate each variable of an equation in turn, save the tree of each
# --> find all variables, don't count for one a variable that appear multiple times
# --> label each variable with a unique identifier, different identifier for same variable appearing multiple times
# --> isolate each of these variables, store all the edges, this gives the oriented graph
# ==> make the union of all edged of all different trees
# ==> does it generated a complete graph ? or can there be something lacking ?


# find subset of equation that, when they are all fusioned in one equation by substitution,
# allow the resolution of the system of equation because the wanted variable is expressed in function
# of only known variables
foreach $subset (powerset(@equations_structures) ) {
	@union_variables = ();
	@union_knowns = ();

	foreach $equation ($subset->@*){
		push @union_variables, $equation->{variables}->@*;
	}
	@union_variables = sort keys %{{ map {$_ => 1} @union_variables }};
	
	# subset of equations contains the variable that we want
	if (not set_inclusion(\@var_wants, \@union_variables))
	{ next }
	
	print "SUBSET";
	print $_->{string} foreach $subset->@*;
	print @union_variables;
	print @union_knowns;
	print "";

	@union_variables = set_difference(\@union_variables, \@var_wants);

	# all the variables of the subset of equations, except the one we want, are known
	if (set_inclusion(\@union_variables, \@var_knowns) ) {
		$enough_information_to_solve_subset = $subset;
		last;
	}
}

if (not $enough_information_to_solve_subset) {
	# print missing_information();
	# exit;
	die "not enough variables known\n";
}

foreach ($enough_information_to_solve_subset->@*) {
	print $_->%{string};
}

print scalar $enough_information_to_solve_subset->@*;

print @union_variables;
print @union_knowns;


# find $master_equation (first equation encountered that contains the unknown variable that we want)
# (remove $master_equation from $enough_information_to_solve_subset->@*)

# put the wanted variable on the left side if it isn't the case

# foreach unknown of the $master_equation
# find in which equation it is, isolate it, then it is ready to be substitued


# while ($equation = shift $enough_information_to_solve_subset->@*) {
#	substitute($equation->{trees}, $master_equation);
#}

# only the idea, form isn't right
#while ($known = shift @var_knowns) {
#	substitute($equation, $master_equation);
#}


#my @postfix = tree_to_postfix($master_equation->{right_side});
#my $result = reverse_polish_calculator(@postfix);

#print "$var_wants[0] = $result\n";

#make_powerset of set of equations tupples --> among this set, find the sets of equations that contain enough information
#together for solving the system of equations

#the union of all the equations ' sets of variable minus the wanted variable, must be equal to the union of all the
#equations'sets of variables that are known

#if not enough information, find the set of minimun set of variables that are needed to solve the system of equations


#substitute($insert, $master_equation);
#$\="";
#tree_to_infix($master_equation->{trees}->{left_side});
#print "=";
#tree_to_infix($master_equation->{trees}->{right_side});
#print "\n";

__END__


only one variable wanted
only one equation containing the variable wanted

subroutine to make isolated variable in the left side if not already in the left side





