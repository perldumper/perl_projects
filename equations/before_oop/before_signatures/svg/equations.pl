#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
# use File::Temp q(tempfile);
# use Time::HiRes q(usleep);

# create an object equation, like the way it is in the python library SymPy


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

# FIRST) doesn't take into account the variable that are unknown but that can be substituted by known variables
# graph ?

# SECOND) is there variables that can't be isolated ? (case where a variable appears more than once and it is 
# not possible to have these variables merged in one, which is alone in)

# THIRD) when all the previous are set, is there orders of substitutions that don't work ?
# or non-unique isolation of variables in a particular equation that doesn't work but at least one other case does ?

# FOUR) how to know if a variable can not be isolated ?
# ==> oriented graph of which variables can be expressed in which other
# ==> a variable cannot be isolated if ... ?




# find_node_path
#	returns chain (array) of nodes from root to node searched for, excluding the node itself
#	returns chain (array) of nodes from root to first variable searched for, excluding the variable itself

# find_nodes
#	returns array of variables
#	returns array of the nodes id and their type


# substitute # substitutes $inserted_equation (expression) INTO $master_equation


#######################
#    PARSING INPUT    #
#######################


$/=undef;
my $input;
my @equations;
my @var_knowns;
my %var_knowns_values;
my @var_wants;

if (@ARGV) {
	if (-e $ARGV[0]) { $input = <ARGV>  }
	else             { $input = $ARGV[0]}
}
elsif (not -t STDIN) { $input = <STDIN> }
else                 {exit}

my @assertions = split /,/, $input;
tr/ //d foreach @assertions;

while(my $assertion = shift @assertions) {

	if($assertion =~							# KNOWNS
			m/^(?<variable>[a-zA-Z][a-zA-Z0-9]*)=(?<value>[0-9]+\.?[0-9]*)$
			|^(?<value>[0-9]+\.?[0-9]*)=(?<variable>[a-zA-Z][a-zA-Z0-9]*)$/x
		) 	{push @var_knowns, $+{variable}; $var_knowns_values{$+{variable}} = $+{value}}

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


##########################
#    MAKING EQUATIONS    #
##########################


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
# 		elsif ($token is a function) {		# FUNCTION
# 			push @stack, $token;
# 		}
		elsif ($token =~ m|[-+*/]|) {		# OPERATOR
# 			while (($#stack >= 0)
# 				  and (( $precedence{$token} < $precedence{$stack[-1]} )
# 					  or (  $precedence{$token} == $precedence{$stack[-1]} and $associativity{$token} eq "left"  ))
# 				  and ( $stack[-1] ne "("  )) {
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
# 			if ( $stack[-1] is a function ) {
# 				push @queue, pop @stack;	# function
# 			}
		}
	} # end foreach
	while ($op = pop @stack){
		push @queue, $op;
	}
	return @queue;
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
	my $equation_string = shift;
	my ($left_expression, $right_expression) = split /=/, $equation_string;

	my @left_infix   = tokenize($left_expression);
	my @left_postfix = infix_to_postfix(@left_infix);
	my $left_tree    = postfix_to_tree(@left_postfix);

	my @right_infix   = tokenize($right_expression);
	my @right_postfix = infix_to_postfix(@right_infix);
	my $right_tree    = postfix_to_tree(@right_postfix);

	return {left_side => $left_tree, right_side=> $right_tree};
}

###########################
#   EQUATION OPERATIONS   #
###########################

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

	# put isolated variable on left
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
		local $\="\n";;
		print_equation($params{equation});
		print "isn't in a form where one variable is alone on of the side of =";
		exit;
	}
}

sub substitute {	# substitute $inserted_equation INTO $master_equation
	my ($inserted_equation, $master_equation) = @_;
	my $inserted_expression = $inserted_equation->{trees}->{right_side};
	my $insertion_point     = $inserted_equation->{trees}->{left_side}->{value};
	my $master_expression   = $master_equation->{trees}->{right_side};
# 	print $master_equation->{string};
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

sub recursive_solve {
	my ($wanted_var, @bag_of_equations) = @_;
	my @reduced_bag_of_equations;
	my $expanded_equation;
	my $temp_expanded_equation;
	my $solution;			# keep final expression, with all unknown variables substitued. varialbes not replaced by numbers
	my $temp_solution;
	my @in_function_of_vars;
	my @known_variables;
	my $var;
	my $variable_value;
	my $eq;

	unless (@bag_of_equations) {return 0}

	sub remove_equation {
		my ($equation, @equation_set) = @_;
		for (my $i = 0; $i < @equation_set; $i++) {
			if ($equation_set[$i]->{string} eq $equation->{string}) {
				splice @equation_set, $i, 1;

			}
		}
		return @equation_set;
	}

	EQUATION:
	foreach my $eq (find_equations_containing_var($wanted_var, @bag_of_equations)) {
		@reduced_bag_of_equations = remove_equation($eq, @bag_of_equations);
		# what if variable appears multiple times ??

# 		isolate(variable=> 1, which=> $wanted_var, equation=> $eq);
# 		$expanded_equation = $eq;
# 		$solution = copy_data_structure($eq);

		$expanded_equation = copy_data_structure($eq);
		isolate(variable=> 1, which=> $wanted_var, equation=> $expanded_equation);
		$solution = copy_data_structure($expanded_equation);

		# what if variable appears multiple times ??
		@in_function_of_vars = set_difference([$eq->{variables}->@*], [$wanted_var]);

		if (set_inclusion(\@in_function_of_vars, \@var_knowns )) {
			foreach $var (@in_function_of_vars) {
				$variable_value = {trees=>
                                  {left_side=> {type=> "variable", value=> $var },
								  right_side=> {type=> "number",   value=> $var_knowns_values{$var} } }};
				substitute($variable_value, $expanded_equation);
			}
			return ($expanded_equation, $solution);			# recursive substitution successful
		}
		else {
			# what if variable appears multiple times ??
			@known_variables = set_difference(\$eq->{variables}->@*, \$eq->{unknowns}->@*);
			@known_variables = set_difference(\@known_variables, [$wanted_var]);			# just in case
			foreach $var (@known_variables) {
				$variable_value = {trees=>
                                  {left_side=> {type=> "variable", value=> $var },
								  right_side=> {type=> "number",   value=> $var_knowns_values{$var} } }};
				substitute($variable_value, $expanded_equation);
			}


			foreach $var (set_difference([$eq->{unknowns}->@*], [$wanted_var])) {
	
				($temp_expanded_equation, $temp_solution) = recursive_solve($var, @reduced_bag_of_equations);
				if ($temp_expanded_equation == 0) {next EQUATION}
				substitute($temp_expanded_equation,  $expanded_equation);
				substitute($temp_solution,  $solution);
			}
			return ($expanded_equation, $solution);			# recursive substitution successful
		}
	}
	return 0;							# recursive substitution unsuccessful, every starting points tried
}


##########################
#    EQUATION  OUTPUT    #
##########################


# postfix stack evaluator
# https://www.youtube.com/watch?v=bebqXO8H4eA
sub reverse_polish_calculator {
	my @queue = @_;
	my @stack;
	my ($left, $right);
	my $symbol;

	while ($symbol = shift @queue) {
		if ($symbol =~ m/\d/){		# NUMBER
			push @stack, $symbol;
		}
		else {						# OPERATOR
			$right = pop @stack;
			$left  = pop @stack;
			if    ($symbol eq "+") { push @stack, $left + $right }
			elsif ($symbol eq "-") { push @stack, $left - $right }
			elsif ($symbol eq "*") { push @stack, $left * $right }
			elsif ($symbol eq "/") { push @stack, $left / $right }
		}
	}
	return pop @stack;
}

# post-order tree traversal, to obtain infix expression
sub tree_to_postfix {
	my $node = shift;
	my @postfix;
	if ($node->{type} eq "operator") {
		push @postfix, tree_to_postfix($node->{left});
		push @postfix, tree_to_postfix($node->{right});
		push @postfix, $node->{value};
		return @postfix;
	}
	else {
		return $node->{value};
	}
}

# in-order tree traversal, to obtain infix expression
sub tree_to_infix {
	my $node = shift;
	my $infix = "";
	if ($node->{type} eq "operator") {
		$infix .= "(";
		$infix .= tree_to_infix($node->{left});
		$infix .= $node->{value};
		$infix .= tree_to_infix($node->{right});
		$infix .= ")";
		return $infix;
	}
	else {
		return $node->{value};
	}
}

sub print_equation {
	my $equation = shift;
	local $\="";
	print tree_to_infix($equation->{trees}->{left_side});
	print " = ";
	print tree_to_infix($equation->{trees}->{right_side});
	print "\n";
}

sub print_equation_info {
	my $equation = shift;
	local $,="";
	local $\="\n";
	print "EQUATION\t",  $equation->{string};
	print "VARIABLES\t", $equation->{variables}->@*;
	print "WANTS\t\t",   $equation->{wants}->@*;
	print "KNOWNS\t\t",  $equation->{knowns}->@*;
	print "UNKNOWNS\t",  $equation->{unknowns}->@*;
	print "";
}

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
		if ($node->{type} eq "operator") { # node has children
			$id = tree_walk2($node->{left}, $id);
			$id = tree_walk2($node->{right}, $id);
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

	sub tree_walk {
		my $node = shift;
		$node->{id} = $id;
		$id++;
		if ($node->{type} eq "operator") { # node has children
			tree_walk($node->{left});
			tree_walk($node->{right});
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
				if (grep {/$var/} $searched_eq->{variables}->@*) {
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


	while ($eq = shift @set_of_equations) {
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
	elsif (ref $struct eq "") {
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

####################
#     GRAPHVIZ     #
####################

sub make_graphviz_tree {
	my $eq = shift;
	################
# 	$eq = copy_data_structure($eq);
# 	delete $eq->{nodes};
# 	delete $eq->{graph};
# 	#mark_nodes($eq);
# 	mark_nodes2($eq);
# 	#mark_nodes3($eq);
# 	make_graph($eq);
# 	$eq->{nodes}->%* = find_nodes($eq);

# 	foreach my $node_id (grep {$eq->{nodes}->{$_}->{type} ne "operator"} keys $eq->{nodes}->%*) {
# 		isolate(node=> 1, which=> $node_id, equation=> $eq);
# 		make_graph($eq);
# 	}

	##################
	my @graphviz;
	push @graphviz, "digraph G {\n";
	foreach my $node (sort keys $eq->{nodes}->%*) {
		push @graphviz, "$node [label = \"$eq->{nodes}->{$node}->{value}\"]\n";
	}
	foreach my $from (sort keys $eq->{graph}->%*) {
		foreach my $to (sort $eq->{graph}->{$from}->@*) {
			push @graphviz, "$from -> $to\n";
		}
	}
	push @graphviz, "}\n";
	return @graphviz;
}

sub make_graphviz_graph {
}



sub print_graphviz_notemp {
	my @graph = @_;
	my $file = "equation-graph";
	open my $FH, ">", "$file.dot" || die "$!";
	print $FH @graph;
	close $FH;
	system "dot -Tpng $file.dot >> $file.png";
	system "sxiv $file.png &";	# image viewer
	unlink "$file.dot";
# 	usleep "50000";				# sleep for 50 milliseconds
	unlink "$file.png";
}



sub print_graphviz {
	my @graph = @_;
	my ($fh, $tmp)=tempfile();
	die "cannot create tempfile" unless $fh;
	print ($fh @graph ) || die "write temp: $!";
	close $fh;
	open my $FH, "<", $tmp || die "$!";
	close $FH;
	system "dot -Tpng $tmp >> $tmp.png";
	system "sxiv $tmp.png &";	# image viewer
	unlink($tmp);
# 	usleep "70000";				# sleep for 50 milliseconds
								# this is required to give sxiv the time it need to read the file before it is deleted
	unlink("$tmp.png");
}

# require having this line if /etc/fstab
# tmpfs   /tmp/ram/   tmpfs    defaults,noatime,nosuid,nodev,noexec,mode=1777,size=32M 0 0
# or execute this in a terminal
# mkdir -p /tmp/ram; sudo mount -t tmpfs -o size=32M tmpfs /tmp/ram/

sub print_graphviz_tmpfs {
	my @graph = @_;
# 	system "rm /tmp/ram/* 2> /dev/null";
	my $file = "/tmp/ram/equation-graph";
	open my $FH, ">", "$file.dot" || die "$!";
	print $FH @graph;
	close $FH;
	system "dot -Tpng $file.dot >> $file.png";
	system "sxiv $file.png &";	# image viewer
# 	unlink "$file.dot";
# 	usleep "50000";				# sleep for 50 milliseconds
# 	unlink "$file.png";
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
# 	return sort keys %{{ map {$_ => 1} @array_c }};
}

sub set_difference {	# set complement	# array_a minus array_b
	my ($array_a, $array_b) = @_;
	my @array_c;
	foreach my $var ($array_a->@*) {
		push @array_c, $var unless grep /$var/, $array_b->@*;
	}
	return sort @array_c;
# 	return sort keys %{{ map {$_ => 1} @array_c }};
}

sub set_union {
	my ($array_a, $array_b) = @_;
	return sort keys %{{ map {$_ => 1} $array_a->@*, $array_b->@* }};
}

sub set_equality {		# require that sort and uniq were applied to each array beforehand
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

sub set_belonging {
	my ($element, $array) = @_;
	if (grep {/$element/} $array->@*)
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
	# from 0..00 to 1..11
	for($counter = 1; $counter < $pow_set_size; $counter++) { 
		@subset = ();
		for($j = 0; $j < $set_size; $j++) { 
			push @subset, $set[$j] if $counter & (1 << $j);
		} 
		push @powerset, [ @subset ];
	} 
	return @powerset;
} 

sub set_product {		# cartesian product of n sets
	my @array_of_aref = @_;
	if (@array_of_aref == 0) {
		return;
	}
	elsif (@array_of_aref == 1) {
		return $array_of_aref[0];
	}
	elsif (@array_of_aref >= 2) {
		my $array_a = shift @array_of_aref;
		my $array_b = shift @array_of_aref;
		my @array_c;
		foreach my $a ($array_a->@*) {
			foreach my $b ($array_b->@*) {
				if (ref $a eq "" and ref $b eq "") {
					push @array_c, [$a,     $b];
				}
				elsif (ref $a eq "ARRAY" and ref $b eq "") {
					push @array_c, [$a->@*, $b];
				}
				elsif (ref $a eq "" and ref $b eq "ARRAY") {
					push @array_c, [$a,     $b->@*];
				}
				elsif (ref $a eq "ARRAY" and ref $b eq "ARRAY") {
					push @array_c, [$a->@*, $b->@*];
				}
			}
		}
		while (my $aref = shift @array_of_aref) {
			@array_c = set_product(\@array_c, $aref);
		}
		return @array_c;
	}
}

sub uniq { keys %{{ map { $_ => 1 } @_ }} }

sub max { (sort { $a <=> $b } @_)[-1] }

sub min { (sort { $a <=> $b } @_)[0] }


#########################
#    END SUBROUTINES    #
#########################

########################
#     MAIN PROGRAM     #
########################

my @equations_structures;
my @wants;
my $var;
my $master_equation;

foreach (@equations) {
	push @equations_structures, { string=> $_, trees=> make_equation($_) }
}

foreach my $eq (@equations_structures) {
# 	mark_nodes($eq);
	mark_nodes2($eq);
# 	mark_nodes3($eq);
	make_graph($eq);
	$eq->{nodes}->%* = find_nodes($eq);

# 	print_graphviz_tmpfs make_graphviz_tree $eq;

	# foreach node that is a variable (necessary in case a variable appears more than once)
	foreach my $node_id (grep {$eq->{nodes}->{$_}->{type} ne "operator"} keys $eq->{nodes}->%*) { # include variables and numbers
		isolate(node=> 1, which=> $node_id, equation=> $eq);
		make_graph($eq);
# 		print_graphviz_tmpfs make_graphviz_tree $eq;
	}
# 	print Dumper $eq->{graph};
# 	print Dumper $eq;
}

# print Dumper $equations_structures[1];

foreach (@equations_structures) {
	$_->{variables}->@* = find_variables($_);
	$_->{knowns}->@* = set_intersection( $_->{variables}, \@var_knowns);
	$_->{wants}->@*  = set_intersection( $_->{variables}, \@var_wants);
	$_->{unknowns}->@* = set_difference( $_->{variables}, \@var_knowns);
#	print_equation_info($_);
}

if (@var_wants == 0) {die "no variable that need to be determined was given"}
my ($wanted_var) = @var_wants;
my ($expanded_equation, $solution) = recursive_solve($wanted_var, @equations_structures);
if ($expanded_equation == 0) { die "can not solve system of equations\n"}

# START CLEAN OUPUT
print_equation($solution);
print_equation($expanded_equation);
my $infix = tree_to_infix($expanded_equation->{trees}->{right_side});
my $infix_result = eval($infix);
print "$wanted_var = $infix_result";
# END CLEAN OUPUT

my @postfix = tree_to_postfix($expanded_equation->{trees}->{right_side});
my $postfix_result = reverse_polish_calculator(@postfix);

if ($infix_result ne $postfix_result) {
	print "infix calculations and postfix calculations differ";
	print "infix  calculation ---> $wanted_var = $infix_result";
	print "postix calculation ---> $wanted_var = $postfix_result";
}



make_overall_graph(@equations_structures);

$,="";

# print_equation($copy);


# print_graphviz make_graphviz_tree $equations_structures[0];
# print_graphviz make_graphviz_tree $equations_structures[1];

print_graphviz_tmpfs make_graphviz_tree $solution;

# find out why there is only a single arrow on the c node in :
# ./equations.pl 'a+b+c=d*e, c=f+g,d,g=78,a=1,b=1,e=1,f=1'


__END__

./equations.pl 'a+b+c=d*e, c=f+g,d,g=78,a=1,b=1,e=1,f=1'
./equations.pl 'c*(d-e)/((f-g)-a*b)=(z-x)*(y+u) , e, c=1,d=2,f=3,g=4,a=h-3*(i+k),h=5,i=6,k=7,b=8,z=4,x=2,y=2,u=2'




