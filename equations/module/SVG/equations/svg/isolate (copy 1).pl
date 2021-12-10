#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

my $input;
$/=undef;

if (@ARGV) {
	if (-e $ARGV[0]) { $input = <ARGV>  }
	else             { $input = $ARGV[0]}
}
elsif (not -t STDIN) { $input = <STDIN> }
else                 {exit}

my $variable;

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

		elsif($expression =~ m/\G(\+)/gc)                  { push @tokens, "+" }
		elsif($expression =~ m/\G(\-)/gc)                  { push @tokens, "-" }
		elsif($expression =~ m/\G(\*)/gc)                  { push @tokens, "*" }
		elsif($expression =~ m/\G(\/)/gc)                  { push @tokens, "/" }

		elsif($expression =~ m/\G(\()/gc)                  { push @tokens, "(" }
		elsif($expression =~ m/\G(\))/gc)                  { push @tokens, ")" }

		else {$end = 1}
	}
	return @tokens;
}

# python friendly version
# sub tokenize {
# 	my $expression = shift;
# 	my @tokens;
# 	my $end = 0;
# 	while(not $end){
# 		if   ($expression =~ m/^ /)                     { 1; $expression =~ s/^ // }
# 		elsif($expression =~ m/^(\d+)/)                 { push @tokens, $1 ; $expression =~ s/^$1//  }
# 		elsif($expression =~ m/^([a-zA-Z][a-zA-Z0-9]*)/){ push @tokens, $1 ; $expression =~ s/^$1//  }

# 		elsif($expression =~ m/^(\+)/)                  { push @tokens, "+" ; $expression =~ s/^\+// }
# 		elsif($expression =~ m/^(\-)/)                  { push @tokens, "-" ; $expression =~ s/^-//  }
# 		elsif($expression =~ m/^(\*)/)                  { push @tokens, "*" ; $expression =~ s/^\*// }
# 		elsif($expression =~ m/^(\/)/)                  { push @tokens, "/" ; $expression =~ s|^/||  }

# 		elsif($expression =~ m/^(\()/)                  { push @tokens, "(" ; $expression =~ s/^\(// }
# 		elsif($expression =~ m/^(\))/)                  { push @tokens, ")" ; $expression =~ s/^\)// }

# 		else {$end = 1}
# 	}
# 	return @tokens;
# }


$\="\n";
$,="\n";
# print @tokens;

# Hunting-Yard algorithm
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
		if ($symbol =~ m/\d|[a-zA-Z]/) {
			push @stack, {type=> "operand", value=> $symbol};
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

sub find_variable_path {
	my ($variable, $expression) = @_;
	my @stack_tree_walk;
	my $node = $expression; # start at root node
	push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};

	while(@stack_tree_walk) {

		if ($node->{type} eq "operand" and $node->{value} eq $variable) {	# variable found
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
	# variable not found in equation's left side
		@operations = find_variable_path($variable, $new_equation->{right_side});
		$equation_side = "right_side";
	}
	if ( not $operations[0]) {
	# variable not found in equation's left side
		die "variable $variable to isolate not found in the equation\n";
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
	

# 	print Dumper @operations;

	
	return $new_equation;
}

# in-order tree traversal, to obtain infix expression
# https://en.wikipedia.org/wiki/Binary_expression_tree#Infix_traversal
sub infix {
	my $token = shift;
	local $\="";
	if (defined $token->{left}) {
		if ($token->{type} eq "operator") {
		   print "(";
		}

		infix($token->{left}) if defined $token->{left};
		print $token->{value};
		infix($token->{right}) if defined $token->{right};

		if ($token->{type} eq "operator") {
		   print ")";
		}
	}
	else {
		print $token->{value};
	}
}

$\="";

# print reverse_polish_calculator @postfix;

# print Dumper postfix_to_tree @postfix;
# print Dumper make_equation $input;

my $equation = make_equation $input;
# print Dumper $equation;

my $expr = $equation->{left_side};
# print Dumper $expr;

# my @path = find_variable_path("e", $expr);
# my @path = find_variable_path("e", $equation->{left_side});
# print Dumper @path;

# my $equation_with_isolated_variable = isolate("e", $equation);
my $equation_with_isolated_variable = isolate($variable, $equation);

# print Dumper $equation_with_isolated_variable;

infix($equation_with_isolated_variable->{left_side});
print "=";
infix($equation_with_isolated_variable->{right_side});
print "\n";

__END__

shunting-yard algorithm from wikipedia
https://en.wikipedia.org/wiki/Shunting-yard_algorithm

# /* This implementation does not implement composite functions,functions with variable number of arguments, and unary operators. */

while there are tokens to be read:
    read a token.
    if the token is a number, then:
        push it to the output queue.
    else if the token is a function then:
        push it onto the operator stack 
    else if the token is an operator then:
        while ((there is an operator at the top of the operator stack)
              and ((the operator at the top of the operator stack has greater precedence)
                  or (the operator at the top of the operator stack has equal precedence and the token is left associative))
              and (the operator at the top of the operator stack is not a left parenthesis)):
            pop operators from the operator stack onto the output queue.
        push it onto the operator stack.
    else if the token is a left parenthesis (i.e. "("), then:
        push it onto the operator stack.
    else if the token is a right parenthesis (i.e. ")"), then:
        while the operator at the top of the operator stack is not a left parenthesis:
            pop the operator from the operator stack onto the output queue.
        # /* If the stack runs out without finding a left parenthesis, then there are mismatched parentheses. */
        if there is a left parenthesis at the top of the operator stack, then:
            pop the operator from the operator stack and discard it
        if there is a function token at the top of the operator stack, then:
            pop the function from the operator stack onto the output queue.
# /* After while loop, if operator stack not null, pop everything to output queue */
if there are no more tokens to read then:
    while there are still operator tokens on the stack:
        # /* If the operator token on the top of the stack is a parenthesis, then there are mismatched parentheses. */
        pop the operator from the operator stack onto the output queue.
exit.
