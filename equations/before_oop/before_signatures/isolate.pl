#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
# use List::Util qw(any);
# use List::MoreUtils;
# use DFA::Simple;
# use Tree::Simple;

$/=undef;
my $input;
my $variable;

if (@ARGV) {
	if (-e $ARGV[0]) { $input = <ARGV>  }
	else             { $input = $ARGV[0]}
}
elsif (not -t STDIN) { $input = <STDIN> }
else                 {exit}

($input, $variable) = split /,/, $input;
$variable =~ tr/ //d;

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
		if ($symbol =~ m/\d|[a-zA-Z]/) {
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

# we want to found the path of the variable to isolate in the binary expression tree
# the variable is necessarily a leaf

sub find_node_path {
	my %param = (variable=> 0, node=> 0);
	%param = @_;
	my $expression = $param{expression};
	my $variable = $param{which} if $param{variable};
	my $node_id  = $param{which} if $param{node};
	my @stack_tree_walk;
	my $node = $expression;			# start at root node
	push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};

	while(@stack_tree_walk) {
	
		if ($param{variable}) {
			if ($node->{type} eq "variable" and $node->{value} eq $variable) {	# variable found
				pop @stack_tree_walk; 											# remove variable node
# 				return map { { $_>%{"type", "value", "side", "id"} } } @stack_tree_walk;
				return map { { $_->%{"type", "value", "side"} } } @stack_tree_walk;
			}
		}
		elsif ($param{node}) {
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

sub mark_nodes {
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
	my %param = (variable=> 0, node=> 0);
	%param = @_;
	my $equation = $param{equation}->{trees};
	my $variable;
	my $node;
	my @operations;
	my $operation;
	our $variable_op_side;
	our $equation_side;

	if ($param{variable}) {
		$variable = $param{which};
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
				die "variable $variable to isolate not found in the equation $param{equation}->{string}\n";
			}
		}
	}
	elsif ($param{node}) {
		$node = $param{which};
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
				die "node $node to isolate not found in the equation $param{equation}->{string}\n";
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
		print_equation($param{equation});
		print "isn't in a form where one variable is alone on of the side of =";
		exit;
	}
	return { trees=> $equation };
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



my $equation->{trees} = make_equation $input;

mark_nodes($equation);
$equation->{nodes}->%* = find_nodes($equation);

# isolate in turn every node that is the variable searched for,
# in case the variable appears more than once
foreach my $node_id (grep { $equation->{nodes}->{$_}->{value} eq $variable  }
                     grep { $equation->{nodes}->{$_}->{type}  eq "variable" }
                     keys $equation->{nodes}->%*) {

		isolate(node=> 1, which=> $node_id, equation=> $equation);
		print_equation($equation);
}




