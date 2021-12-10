#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

# DATA FLOW
# parse arguments -> tokenize = infix -> infix_to_postfix -> postfix_to_tree -> make_equation
# find_variable_path -> isolate -> find_variables -> substitution


my $input;
$/=undef;

if (@ARGV) {
	if (-e $ARGV[0]) { $input = <ARGV>  }
	else             { $input = $ARGV[0]}
}
elsif (not -t STDIN) { $input = <STDIN> }
else                 {exit}

my $variable;

my @assertions = split /,/, $input;
tr/ //d for @assertions;

my @equations;
my @var_knowns;
my @var_wants;

while(my $assertion = shift @assertions) {

	if($assertion =~							# HAVES
			m/^([a-zA-Z][a-zA-Z0-9]*)=[0-9]+\.?[0-9]*$
			|^[0-9]+\.?[0-9]*=([a-zA-Z][a-zA-Z0-9]*)$/x
		) {push @var_knowns, $+}

	elsif($assertion =~ m/=/)
		{push @equations, $assertion}			# EQUATIONS
	else {push @var_wants, $assertion}			# WANTS
}


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
	my ($variable, $equation) = @_;
	my $new_equation = $equation;
	my $operation;
	our $variable_op_side;

	my @operations = find_variable_path($variable, $new_equation->{left_side});
	our $equation_side = "left_side";

	if ( not $operations[0]) {
		if($new_equation->{left_side}->{value} eq $variable) {
			return $new_equation;
		}
		else {
		# variable not found in equation's left side
			@operations = find_variable_path($variable, $new_equation->{right_side});
			$equation_side = "right_side";
		}
	}
	if ( not $operations[0]) {
		if($new_equation->{right_side}->{value} eq $variable) {
			return $new_equation;
		}
		else {
		# variable not found in equation's left side
			die "variable $variable to isolate not found in the equation $input\n";
		}
	}

	sub other_equation_side { return "right_side" if $equation_side eq "left_side"; return "left_side" }
	sub other_variable_op_side { return "right" if $variable_op_side eq "left"; return "left" }

	while ($operation = shift @operations) {
		$variable_op_side = $operation->{side};

		if ($operation->{value} eq "*") {
			$new_equation->{other_equation_side()} = { type=> "operator", value=> "/",
                                                       left=> $new_equation->{other_equation_side()},
                                                      right=> $new_equation->{$equation_side}->{other_variable_op_side()} };
			$new_equation->{$equation_side} = $new_equation->{$equation_side}->{$variable_op_side};
		}
		elsif ($operation->{value} eq "/") {
			$new_equation->{other_equation_side()} = { type=> "operator", value=> "*",
                                                       left=> $new_equation->{other_equation_side()},
                                                      right=> $new_equation->{$equation_side}->{right} };
			$new_equation->{$equation_side} = $new_equation->{$equation_side}->{left};
			if ($variable_op_side eq "right") {
				$equation_side = other_equation_side();
				unshift @operations, {type=> "operator", value=> "*", side=> "right" };
			}
		}
		elsif ($operation->{value} eq "+") {
			$new_equation->{other_equation_side()} = { type=> "operator", value=> "-",
                                                       left=> $new_equation->{other_equation_side()},
                                                      right=> $new_equation->{$equation_side}->{other_variable_op_side()} };
			$new_equation->{$equation_side} = $new_equation->{$equation_side}->{$variable_op_side};
		}
		elsif ($operation->{value} eq "-") {
			$new_equation->{other_equation_side()} = { type=> "operator", value=> "+",
                                                       left=> $new_equation->{other_equation_side()},
                                                      right=> $new_equation->{$equation_side}->{right} };
			$new_equation->{$equation_side} = $new_equation->{$equation_side}->{left};
			if ($variable_op_side eq "right") {
				$equation_side = other_equation_side();
				unshift @operations, {type=> "operator", value=> "+", side=> "right" };
			}
		}
	}
	return $new_equation;
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

sub find_variable_path {
	my ($variable, $expression) = @_;
	my @stack_tree_walk;
	my $node = $expression; # start at root node
	push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};

	while(@stack_tree_walk) {

		if ($node->{type} eq "variable" and $node->{value} eq $variable) {	# variable found
			pop @stack_tree_walk; 											# remove variable node
			return map { { $_->%{"type", "value", "side"} } } @stack_tree_walk;
		}
		elsif ($node->{type} eq "operator") {					# if node is not a leaf, visit children nodes
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
				$node = $stack_tree_walk[-1];
			}
		}
		else {													# if the node is a leaf, go back to parent node
			pop @stack_tree_walk;
			$node = $stack_tree_walk[-1];
		}
	}
	return 0; # variable not found, $operations[0] = 0, which evaluates to false in boolean context
}



sub find_variables {
	my $equation = shift;
	my $left_expression = $equation->{left_side};
	my $right_expression = $equation->{right_side};
	my @stack_tree_walk;
	my @variables;
	my $node;

	foreach my $expression ($left_expression, $right_expression) {
		@stack_tree_walk = ();
		$node = $expression; # start at root node
		push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};

		while(@stack_tree_walk) {

			if ($node->{type} eq "variable") {
				push @variables, $node->{value};
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
					$node = $stack_tree_walk[-1];
				}
			}
			else {
				pop @stack_tree_walk;
				$node = $stack_tree_walk[-1];
			}
		}
	}
	return keys %{ {map { $_ => 1 } @variables} }; # return uniq variables
}

sub substitution {
	my ($inserted_equation, $master_equation) = @_;
	my $inserted_expression = $inserted_equation->{right_side};
	my $insertion_point     = $inserted_equation->{left_side}->{value};
	my $master_expression   = $master_equation->{trees}->{right_side};
	my @stack_tree_walk;
	my $node = $master_expression;
	push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};

	while(@stack_tree_walk) {

		if ($node->{type} eq "variable" and $node->{value} eq $insertion_point) {
			%$node = $inserted_expression->%*;
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
				$node = $stack_tree_walk[-1];
			}
		}
		else {
			pop @stack_tree_walk;
			$node = $stack_tree_walk[-1];
		}
	}
}

########################
#    SET OPERATIONS    #
########################

sub set_intersection {
	my ($array_a, $array_b)=@_;
	my @array_c;
	foreach my $var ($array_a->@*) {
		push @array_c, $var if grep /$var/, $array_b->@*;
	}
	return @array_c;
}

sub set_difference {
	my ($array_a, $array_b)=@_;
	my @array_c;
	foreach my $var ($array_a->@*) {
		push @array_c, $var unless grep /$var/, $array_b->@*;
	}
	return @array_c;
}

sub set_union {
	my ($array_a, $array_b)=@_;
	return keys %{{ map {$_ => 1} $array_a->@*, $array_b->@* }};
}

sub powerset {
}

sub set_of_equations_with_enough_information {
#make_powerset of set of equations tupples --> among this set, find the sets of equations that contain enough information
#together for solving the system of equations

#the union of all the equations ' sets of variable minus the wanted variable, must be equal to the union of all the
#equations'sets of variables that are known


#if not enough information, find the set of minimun set of variables that are needed to solve the system of equations


#for each equation, find knowns and wants and unknowns

}

my @equations_structures;
my (@knowns, @wants);
my $var;
my $master_equation;

foreach (@equations) {
	push @equations_structures, { string=> $_, trees=> make_equation($_) }
}
foreach (@equations_structures) {
	$_->{variables}->@* = find_variables($_->{trees});
}
foreach (@equations_structures) {
	$_->{knowns}->@* = set_intersection( $_->{variables}, \@var_knowns);
	$_->{wants}->@*  = set_intersection( $_->{variables}, \@var_wants);
}
foreach (@equations_structures) {
	$_->{unknowns}->@* = set_difference( $_->{variables}, \@var_knowns);
}
for (my $i=0; $i < @equations_structures; $i++ ) {
	if (@wants) {
		$master_equation = $equations_structures[$i];
		splice @equations_structures, $i, 1;
	 }
}

$,="";
$\="\n";

foreach (@equations_structures) {
	print "EQUATION\t",       $_->{string};
	print "VARIABLES\t", sort $_->{variables}->@*;
	print "WANTS\t\t",   sort $_->{wants}->@*;
	print "KNOWNS\t\t",  sort $_->{knowns}->@*;
	print "UNKNOWNS\t",  sort $_->{unknowns}->@*;
	print "";
}


#substitution($insert, $master_equation);
#$\="";
#tree_to_infix($master_equation->{trees}->{left_side});
#print "=";
#tree_to_infix($master_equation->{trees}->{right_side});
#print "\n";

__END__


only one variable wanted
only one equation containing the variable wanted







