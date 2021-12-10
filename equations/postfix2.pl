#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use Data::Dumper;
use List::Util qw(uniq any);
use Math::Trig;

##########################
#    MATHS OPERATIONS    #
##########################

my %precedence = (
	exp   => 4,
	ln    => 4,
	log   => 4,
	log10 => 4,
	exp10  => 4,

	sqrt  => 4,
	sin   => 4,
	cos   => 4,
	tan   => 4,
	arcsin => 4,
	arccos => 4,
	arctan => 4,
	pow2   => 4,

	"nth-root" => 3,
	"%"   => 3,		# ???
	"^"   => 3,
# 	sqrt  => 3,

	"*"   => 2,
	"/"   => 2,

	"+"   => 1,
	"-"   => 1,
	"("   => 0,
	")"   => 0,
# 	"("   => 5,
# 	")"   => 5,
);

my %left_associative = (
	"*"   => 1,
	"/"   => 1,
	"+"   => 1,
	"-"   => 1,
	"%"   => 1,

	"nth-root" => 0,
	"^"   => 0,
	sqrt  => 0,
	pow2  => 0,

	exp   => 0,
	ln    => 0,
	log   => 0,
	log10 => 0,
	exp10 => 0,

	sin   => 0,
	cos   => 0,
	tan   => 0,
	arcsin   => 0,
	arccos   => 0,
	arctan   => 0,
);

my %right_associative = (
	"*"   => 1,
	"/"   => 0,
	"+"   => 1,
	"-"   => 0,
	"%"   => 0,

	"^"   => 1,
	"nth-root" => 1,
	sqrt  => 1,
	pow2  => 1,

	exp   => 1,
	ln    => 1,
	log   => 1,
	log10 => 1,
	exp10 => 1,

	sin   => 1,
	cos   => 1,
	tan   => 1,
	arcsin   => 1,
	arccos   => 1,
	arctan   => 1,
);

my %inverse = (
	"+"   => "-",
	"-"   => "+",
	"*"   => "/",
	"/"   => "*",
# 	"%"   => "",		# ??? arithmetic function / algorithm, Euclidean division ?

	"^"   => "nth-root",		# n-root, exponent form ?	# pow 1/n
	"nth-root" => "^",
	pow2  => "sqrt",
	sqrt  => "pow2",

	exp   => "ln",
	ln    => "exp",
	log   => "exp",
	log10 => "exp10",
	exp10 => "log10",

	sin   => "arcsin",
	cos   => "arccos",
	tan   => "arctan",
	arcsin  => "sin",
	arccos  => "cos",
	arctan  => "tan",
);


#######################
#    PARSING INPUT    #
#######################

$/=undef;
$\="\n";
my $input;
my @equations;
my @var_knowns;
my %var_knowns_values;
my @var_wants;

my $debug = 0;

if (@ARGV) {
	if ($ARGV[0] eq "debug") { shift; $debug = 1 }
	if (-e $ARGV[0]) { $input = <ARGV>  }
	else             { $input = $ARGV[0]}
}
elsif (not -t STDIN) { $input = <STDIN> }
else                 { exit }

my $level=0;
my $buf="";
my @assertions;

foreach (split //, $input) {
# 	print "$level $_";
	$level++ if $_ eq "(";
	$level-- if $_ eq ")";
	if ($level==0 and $_ eq ",") {
# 		print "here $_";
# 		print "buf $buf";
		push @assertions, $buf;
		$buf="";
	}
	else { $buf .= $_ }
}
# print "END buf $buf";
push @assertions, $buf if length $buf > 0;


s/^ +//g foreach @assertions;
s/ +$//g foreach @assertions;

while (my $assertion = shift @assertions) {

	if ($assertion =~							# KNOWNS
			m/ ^ (?<variable> [a-zA-Z][a-zA-Z0-9]* ) \s* = \s* (?<value> [0-9]+ \.? [0-9]* ) $
			|  ^ (?<value> [0-9]+ \.? [0-9]* ) \s* = \s* (?<variable> [a-zA-Z][a-zA-Z0-9]* ) $ /x
		)   { push @var_knowns, $+{variable}; $var_knowns_values{$+{variable}} = $+{value} }

	elsif ($assertion =~ m/=/)
			{ push @equations, $assertion }		# EQUATIONS
	else	{ push @var_wants, $assertion }		# WANTS
}

@var_knowns = sort @var_knowns;
@var_wants = sort @var_wants;

sub tokenize {
	my $expression = shift;
	my @tokens;
	my $end = 0;
	while(not $end){
		if    ($expression =~ m/\G /gc)                     { 1; }
		elsif ($expression =~ m/\G,/gc)                     { 1; }

		elsif ($expression =~ m/\G\+/gc)                    { push @tokens, "+" }
		elsif ($expression =~ m/\G\-/gc)                    { push @tokens, "-" }
		elsif ($expression =~ m/\G\*/gc)                    { push @tokens, "*" }
		elsif ($expression =~ m/\G\//gc)                    { push @tokens, "/" }
		elsif ($expression =~ m/\G\^/gc)                    { push @tokens, "^" }
		elsif ($expression =~ m/\G\%/gc)                    { push @tokens, "%" }

		elsif ($expression =~ m/\G\(/gc)                    { push @tokens, "(" }
		elsif ($expression =~ m/\G\)/gc)                    { push @tokens, ")" }

		elsif ($expression =~ m/\Gsqrt/gc)                  { push @tokens, "sqrt"  }
		elsif ($expression =~ m/\Gexp/gc)                   { push @tokens, "exp"   }
		elsif ($expression =~ m/\Gln/gc)                   	{ push @tokens, "ln"    }
		elsif ($expression =~ m/\Glog10/gc)                 { push @tokens, "log10" }
		elsif ($expression =~ m/\Glog/gc)                   { push @tokens, "log"   }
		elsif ($expression =~ m/\Gnth-root/gc)              { push @tokens, "nth-root" }
		elsif ($expression =~ m/\Gsin/gc)                   { push @tokens, "sin"   }
		elsif ($expression =~ m/\Gcos/gc)                   { push @tokens, "cos"   }
		elsif ($expression =~ m/\Gtan/gc)                   { push @tokens, "tan"   }
		elsif ($expression =~ m/\Garcsin/gc)                { push @tokens, "arcsin"   }
		elsif ($expression =~ m/\Garccos/gc)                { push @tokens, "arccos"   }
		elsif ($expression =~ m/\Garctan/gc)                { push @tokens, "arctan"   }

		elsif ($expression =~ m/\G(\d+)/gc)                 { push @tokens, $1  }
		elsif ($expression =~ m/\G([a-zA-Z][a-zA-Z0-9]*)/gc){ push @tokens, $1  }

		else { $end = 1 }
	}
	return @tokens;
}


sub infix_to_postfix {
# 	my @tokens = @_;
# 	my @stack;
# 	my @queue;
	our @tokens = @_;
	our @stack;
	our @queue;
	my $token;
	my $op;

	printf "     %5s     %-10s%10s\n", "STACK", "QUEUE", "TOKENS" if $debug;
	sub print_state { printf "     %-10s%-14s%-20s\n", join("", @stack), join("",@queue), join("",@tokens) }
	print_state() if $debug;

	while ( $token = shift @tokens) {
		if ($token =~ m/^(?:sqrt|exp|ln|log|log10|exp10|pow2|nth-root|arcsin|arccos|arctan|sin|cos|tan)$/ ) { # FUNCTION
			push @stack, $token;
		}

		elsif ($token =~ /\d|[a-zA-Z]/) {	# NUMBER or VARIABLE
			push @queue, $token;
		}

		elsif ($token =~ m#^(?:[-+*/^%])$#) {		# OPERATOR		# shoud infix nth-root be included ??
			while (($#stack >= 0)
				  and (( $precedence{$token} < $precedence{$stack[-1]} )
					  or (  $precedence{$token} == $precedence{$stack[-1]} and $left_associative{$token} ))
				  and ( $stack[-1] ne "("  )) {

				push @queue, pop @stack;
				print_state() if $debug;
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
				print_state() if $debug;
			}
			if (@stack) {
				if ( $stack[-1] =~ m/^(?:sqrt|pow2|exp|exp10|ln|log|log10|nth-root|arcsin|arccos|arctan|sin|cos|tan)$/ ) {
					push @queue, pop @stack;	# function
					print_state() if $debug;
				}
			}
		}
	} # end while

	print_state() if $debug;

	while ($op = pop @stack){
		push @queue, $op;
		print_state() if $debug;
	}
	print_state() if $debug;
	return @queue;
}




# https://en.wikipedia.org/wiki/Binary_expression_tree#Construction_of_an_expression_tree
sub postfix_to_tree {
	my @queue = @_;
	my @stack;
	my $left;
	my $right;
	my $argument;
	while (my $symbol = shift @queue) {
		if ($symbol =~ m/\d/) {											# NUMBER
			push @stack, {type=> "number", value=> $symbol};
		}
		elsif ($symbol =~ m|^[-+/*^%]$|) {								# OPERATOR
			$right = pop @stack;
			$left  = pop @stack;
			push @stack, {type=> "binary_op", value=> $symbol, left=> $left, right=> $right};
		}
		elsif ($symbol =~ m/^(?:sqrt|exp|exp10|ln|log|log10|pow2|arcsin|arccos|arctan|sin|cos|tan)$/) {	# FUNCTION
			$argument = pop @stack;
			push @stack, {type=> "unary_op", value=> $symbol, operand=> $argument};
		}
		elsif ($symbol =~ m/^nth-root$/) {
			$right = pop @stack;
			$left  = pop @stack;
			push @stack, {type=> "binary_op", value=> $symbol, left=> $left, right=> $right};
			# defined as an operator to avoid making a special case for it in the tree walking functions
			# because all the other functions take only one argument
		}
		elsif ($symbol =~ m/[a-zA-Z]/) {								# VARIABLE
			push @stack, {type=> "variable", value=> $symbol};
		}
	}
	return pop @stack;
}


sub postfix_to_infix {
	our @queue = @_;
	our @stack = ();
	my $token;
	my $level;
	my @right;
	my @left;
	my @operand;

	sub get_operand {
		my @operand;
		my $level;
		if ($stack[-1] =~ m/\d|[a-zA-Z]/) {
# 		if ($stack[-1] =~ m/\d|[a-zA-Z]|^(?:sqrt|exp|exp10|ln|log|log10|pow2|nth-root|arcsin|arccos|arctan|sin|cos|tan)$/) {

			unshift @operand, pop @stack;
			if (@stack) {
				until ($stack[-1] =~ m/\d|[a-zA-Z]/ or $stack[-1] eq ")" ) {
# 				until ($stack[-1] =~ m/\d|[a-zA-Z]|^(?:sqrt|exp|exp10|ln|log|log10|pow2|nth-root|arcsin|arccos|arctan|sin|cos|tan)$/ or $stack[-1] eq ")" ) {
					unshift @operand, pop @stack;
				}
			}
		}
		elsif ($stack[-1] eq ")" ) {
			$level = 1;
			while ($level > 0) {
				unshift @operand, pop @stack;
				$level-- if $stack[-1] eq "(" ;
				$level++ if $stack[-1] eq ")" ;
			}
			unshift @operand, pop @stack;
		}

		if (@stack) {
			if ($stack[-1] =~ m/^(?:sqrt|exp|exp10|ln|log|log10|pow2|nth-root|arcsin|arccos|arctan|sin|cos|tan)$/) {
				unshift @operand, pop @stack;
			}
		}
		return @operand;
	}

	sub get_minimum_op_preced_operand {
		my @operand = @_;
		my $level = 0;
		my $minimum = 3;	# 3 is strictly superior to the highest precedence of all operators
		for (my $i=0; $i < @operand; $i++) {
			$level++ if $operand[$i] eq "(" ;		# than token operator if we remove paren aroud right operand
			$level-- if $operand[$i] eq ")" ;
			if ($level == 1 and $operand[$i] =~ m|^[-+/*%^]$|) {
				$minimum = $precedence{ $operand[$i] } if $precedence{ $operand[$i] } < $minimum;
			}
		}
		return $minimum;
	}


	sub can_remove_outer_parens_right_operand {
		my $external_op = shift;
		my @right = @_;
		
		my $EXT_OP_right_assoc = $right_associative{ $external_op };
		my $EXT_OP_preced      = $precedence{ $external_op };
		my $minimum_OP_preced_OPERAND;

		if (@right == 1) {												# number
			if ($right[0] =~ m/\d|[a-zA-Z]/) {
				return 0;	# bare number, no parentheses to remove
			}
		}
		elsif (@right == 3) {											# number OP number / ( number )
			if ($right[0] eq "(" and $right[1] =~ m/\d|[a-zA-Z]/ ) {	# ( number )
				return 1;
			}
			elsif ($right[0] =~ /\d|[a-zA-Z]/ and $right[1] =~ m|^[-+/*%^]$| ) {	# number OP number
				
				$minimum_OP_preced_OPERAND = $precedence{ $right[1] };

				if (  (not $EXT_OP_right_assoc and $EXT_OP_preced < $minimum_OP_preced_OPERAND)
						or  ($EXT_OP_right_assoc and $EXT_OP_preced <= $minimum_OP_preced_OPERAND)  ) {
					return 1;
				}
				else {
					return 0;
				}
			}
		}
		elsif (@right >= 5) {	# at least 2 numbers, 1 binary operator, 2 parentheses
# 		elsif (@right >= 4) {	# at least 2 numbers, 1 binary operator, 2 parentheses

			if ($right[0] =~ m/^(?:sqrt|exp|exp10|ln|log|log10|pow2|nth-root|arcsin|arccos|arctan|sin|cos|tan)$/
				and $right[1] eq "(") {
				return 0;
			}

			$minimum_OP_preced_OPERAND = get_minimum_op_preced_operand(@right);

			if (  (not $EXT_OP_right_assoc and $EXT_OP_preced < $minimum_OP_preced_OPERAND)
					or  ($EXT_OP_right_assoc and $EXT_OP_preced <= $minimum_OP_preced_OPERAND)  ) {
				return 1;
			}
			else {
				return 0;
			}
		}
	}


	sub can_remove_outer_parens_left_operand {
		my $external_op = shift;
		my @left = @_;
		
		my $EXT_OP_left_assoc = $left_associative{ $external_op };
		my $EXT_OP_preced     = $precedence{ $external_op };
		my $minimum_OP_preced_OPERAND;

		if (@left == 1) {												# number
			if ($left[0] =~ m/\d|[a-zA-Z]/) {
				return 0;
			}
		}
		elsif (@left == 3) {											# number OP number / ( number )
			if ($left[0] eq "(" and $left[1] =~ m/\d|[a-zA-Z]/ ) {		# ( number )
				return 1;
			}
			elsif ($left[0] =~ /\d|[a-zA-Z]/ and $left[1] =~ m|^[-+/*%^]$| ) {	# number OP number
				
				$minimum_OP_preced_OPERAND = $precedence{ $left[1] };

				if (  (not $EXT_OP_left_assoc and $minimum_OP_preced_OPERAND > $EXT_OP_preced )
						or  ($EXT_OP_left_assoc and $minimum_OP_preced_OPERAND >= $EXT_OP_preced )  ) {
					return 1;
				}
				else {
					return 0;
				}
			}
		}
		elsif (@left >= 5) {	# at least 2 numbers, 1 binary operator, 2 parentheses

			$minimum_OP_preced_OPERAND = get_minimum_op_preced_operand(@left);

			if (  (not $EXT_OP_left_assoc and $minimum_OP_preced_OPERAND > $EXT_OP_preced )
					or  ($EXT_OP_left_assoc and $minimum_OP_preced_OPERAND >= $EXT_OP_preced )  ) {
				return 1;
			}
			else {
				return 0;
			}
		}
	}

	sub remove_outer_parens { splice @_, 1, -1 }

	while ($token = shift @queue) {

		if ($token =~ m#^(?:[-+/*%^]|nth-root)$#) {

			@right = get_operand();
			@left  = get_operand();
# 			print "RIGHT @right";
# 			print "LEFT @left";
# 			print "STACK @stack";

			if (can_remove_outer_parens_right_operand($token, @right)) {
				if (can_remove_outer_parens_left_operand($token, @left)) {
					@right = remove_outer_parens(@right);
					@left  = remove_outer_parens(@left);
				}
				else {
					@right = remove_outer_parens(@right);
				}
			}
			else {
				if (can_remove_outer_parens_left_operand($token, @left)) {
					@left = remove_outer_parens(@left);
				}
			}
# 			print "after remove parens";
# 			print "RIGHT @right";
# 			print "LEFT @left";

			if ($token eq "nth-root") {
# 				push @stack, $token, "(", @right, ",", @left, ")";
# 				push @stack, $token, "(", @right, @left, ")";
				push @stack, $token, "(", @left, @right, ")";
			}
			else {
				push @stack, "(", @left, $token, @right, ")";
			}
# 			print "STACK @stack";
		}
		elsif ($token =~ m/^(?:sqrt|exp|exp10|ln|log|log10|pow2|arcsin|arccos|arctan|sin|cos|tan)$/ ) {
			@operand = get_operand();
			push @stack, $token, "(", @operand, ")";
		}
		elsif ($token =~ m/\d|[a-zA-Z]/) {
			push @stack, $token;
		}
	}

	if ($stack[0] eq "(") {
		return remove_outer_parens(@stack)
	}
	else {
		return @stack;
	}
}


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
		elsif ($symbol =~ m|^[-+/*^%]$|) {								# OPERATOR
			$right = pop @stack;
			$left  = pop @stack;
			if    ($symbol eq "+") { push @stack, $left +  $right }
			elsif ($symbol eq "-") { push @stack, $left -  $right }
			elsif ($symbol eq "*") { push @stack, $left *  $right }
			elsif ($symbol eq "/") { push @stack, $left /  $right }
			elsif ($symbol eq "^") { push @stack, $left ** $right }
			elsif ($symbol eq "%") { push @stack, $left %  $right }
		}
		elsif ($symbol =~ m/^(?:sqrt|exp|exp10|ln|log|log10|pow2|nth-root|arcsin|arccos|arctan|sin|cos|tan)$/ ) {
			if    ($symbol eq "exp" )  { push @stack, exp pop @stack }
			elsif ($symbol eq "exp10") { push @stack, 10 ** pop @stack }
			elsif ($symbol eq "ln"   ) { push @stack, log pop @stack }
			elsif ($symbol eq "log"  ) { push @stack, log pop @stack }
			elsif ($symbol eq "log10") {
				$right = pop @stack;
				push @stack, (log $right) / (log 10)
			}
			elsif ($symbol eq "sqrt" ) { push @stack, sqrt pop @stack }
			elsif ($symbol eq "pow2" ) { push @stack, (pop @stack) ** 2 }
			elsif ($symbol eq "nth-root") {
				$right = pop @stack;
				$left  = pop @stack;
				push @stack, $left ** (1 / $right)
			}

			elsif ($symbol eq "sin"  )  { push @stack, sin pop @stack }
			elsif ($symbol eq "cos"  )  { push @stack, cos pop @stack }
			elsif ($symbol eq "tan"  )  { push @stack, tan pop @stack }
# 			elsif ($symbol eq "tan"  ) {
# 				$right = pop @stack;
# 				push @stack, sin ($right) / cos ($right)
# 			}
			elsif ($symbol eq "arcsin"  ) { push @stack, asin( pop @stack ) }
			elsif ($symbol eq "arccos"  ) { push @stack, acos( pop @stack ) }
			elsif ($symbol eq "arctan"  ) { push @stack, atan( pop @stack ) }
		}
	}
	return pop @stack;
}

sub tree_to_postfix {
	my $node = shift;
	my @postfix;
	if ($node->{type} eq "binary_op") {
		push @postfix, tree_to_postfix($node->{left});
		push @postfix, tree_to_postfix($node->{right});
		push @postfix, $node->{value};
		return @postfix;
	}
	elsif ($node->{type} eq "unary_op") {
		push @postfix, tree_to_postfix($node->{operand});
		push @postfix, $node->{value};
		return @postfix;
	}
	else {
		return $node->{value};
	}
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

	foreach my $expression ($left_expression, $right_expression) {
		@stack_tree_walk = ();
		$node = $expression; # start at root node
		push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};

		while(@stack_tree_walk) {

			$nodes{$node->{id}} = { type=> $node->{type},
			                       value=> $node->{value},
			                          id=> $node->{id} };

			if ($node->{type} eq "binary_op") {				# operator
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

		if ($operation->{type} eq "binary_op") {

			if ($left_associative{$operation->{value}} and $right_associative{$operation->{value}}) {	# ADDITION MUTIPLICATION

				$equation->{other_equation_side()} = { type=> "binary_op", value=> $inverse{ $operation->{value} },
															 id=> $operation->{id},
														   left=> $equation->{other_equation_side()},
														  right=> $equation->{$equation_side}->{other_variable_op_side()} };
				$equation->{$equation_side} = $equation->{$equation_side}->{$variable_op_side};
			}

			elsif ($left_associative{ $operation->{value} }) {	#  SUBSTRACTION DIVISION
				$equation->{other_equation_side()} = { type=> "binary_op", value=> $inverse{ $operation->{value} },
															 id=> $operation->{id},
														   left=> $equation->{other_equation_side()},
														  right=> $equation->{$equation_side}->{right} };
				$equation->{$equation_side} = $equation->{$equation_side}->{left};
				if ($variable_op_side eq "right") {
					$equation_side = other_equation_side();
					unshift @operations, {type=> "binary_op", value=> $inverse{ $operation->{value} },
												side=> "right", id=> $operation->{id} };
				}
			}
			elsif ($right_associative{ $operation->{value} }) {	#  POWER (verify this one)
				$equation->{other_equation_side()} = { type=> "binary_op", value=> $inverse{ $operation->{value} },
															 id=> $operation->{id},
														  right=> $equation->{$equation_side}->{left},
														   left=> $equation->{other_equation_side()},
# 														   left=> $equation->{$equation_side}->{left},
# 														  right=> $equation->{other_equation_side()},
																									 };
				$equation->{$equation_side} = $equation->{$equation_side}->{right};
				if ($variable_op_side eq "left") {
					$equation_side = other_equation_side();
					unshift @operations, {type=> "binary_op", value=> $inverse{ $operation->{value} },
												side=> "left", id=> $operation->{id} };
				}
			}
		}
		elsif ($operation->{type} eq "unary_op") {	#  FUNCTIONS sqrt nth-root pow2 exp10 exp ln log log10 sin cos tan
				$equation->{other_equation_side()} = { type=> "unary_op", value=> $inverse{ $operation->{value} },
														     id=> $operation->{id},
													    operand=> $equation->{other_equation_side()} };
				$equation->{$equation_side} = $equation->{$equation_side}->{operand};
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

	sub remove_equation {	# eliminate equations already substituted once to avoid "loops"
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
		elsif ($node->{type} eq "binary_op") {
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
				if (@stack_tree_walk) {
					$node = $stack_tree_walk[-1];
				}
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
		else {
			pop @stack_tree_walk;
			$node = $stack_tree_walk[-1];
		}
	}
}

sub mark_nodes2 {
	my $equation = shift;
	our $id = 0;	# global variable within the enclosing block, get reset to 0 for each equation
# 	my $id = 0;		# not reset, the nodes id of the next equation don't start at 0

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


sub set_intersection {
	my ($array_a, $array_b) = @_;
	my @array_c;
	foreach my $var ($array_a->@*) {
# 		push @array_c, $var if grep {/$var/} $array_b->@*;
		push @array_c, $var if any {/$var/} $array_b->@*;
	}
	return sort @array_c;
# 	return sort keys %{{ map {$_ => 1} @array_c }};
}

sub set_difference {	# set complement	# array_a minus array_b
	my ($array_a, $array_b) = @_;
	my @array_c;
	foreach my $var ($array_a->@*) {
# 		push @array_c, $var unless grep {/$var/} $array_b->@*;
		push @array_c, $var unless any {/$var/} $array_b->@*;
	}
	return sort @array_c;
# 	return sort keys %{{ map {$_ => 1} @array_c }};
}

sub set_inclusion {		# is array_a included in array_b
	my ($array_a, $array_b) = @_;
	if (set_equality($array_a, [set_intersection($array_a, $array_b)]))
	{ return 1 }
	else
	{ return 0 }
}


sub set_union {
	my ($array_a, $array_b) = @_;
# 	return sort keys %{{ map {$_ => 1} $array_a->@*, $array_b->@* }};
	return sort uniq $array_a->@*, $array_b->@*;
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

sub print_equation {
	my $equation = shift;
	local $\="";
	local $,="";
 	print postfix_to_infix( tree_to_postfix($equation->{trees}->{left_side}) );
	print " = ";
 	print postfix_to_infix( tree_to_postfix($equation->{trees}->{right_side}) );
	print "\n";
}


sub print_equation_info {
	my $equation = shift;
	local $,="";
	local $\="\n";
	print "EQUATION\t",  $equation->{string};
	print "VARIABLES\t", sort $equation->{variables}->@*;
	print "WANTS\t\t",   sort $equation->{wants}->@*;
	print "KNOWNS\t\t",  sort $equation->{knowns}->@*;
	print "UNKNOWNS\t",  sort $equation->{unknowns}->@*;
	print "";
}

my @tokens;
# my @postfix;
my @infix;
my $tree;
my $result;

#$,="\n";
$,=" ";
#$,="";
$\="\n";

# foreach (@equations) {
# foreach (@assertions) {
# 
# 	@infix   = tokenize($_);
# 	@postfix = infix_to_postfix(@infix);
# 	$tree    = postfix_to_tree(@postfix);
# 	$result  = reverse_polish_calculator(@postfix);
# 
# 	print @infix;
# 	print @postfix;
# 	print Dumper $tree;
# 	print $result;
# 
# 	@postfix = tree_to_postfix($tree);
# 	@infix   = postfix_to_infix(@postfix);
# 	print @postfix;
# 	print @infix;
# 
# }

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

# __END__

foreach my $eq (@equations_structures) {
	mark_nodes2($eq);
	make_graph($eq);
	$eq->{nodes}->%* = find_nodes($eq);

	# foreach node that is a variable (necessary in case a variable appears more than once)

	foreach my $node_id (	grep {$eq->{nodes}->{$_}->{type} =~ m/variable|number/} # include variables and numbers
							keys $eq->{nodes}->%* )
	{
# 		print "NODE";
# 		print $eq->{nodes}->{$node_id}->%*;
# 		print Dumper $eq->{trees};
# 		isolate(node=> 1, which=> $node_id, equation=> $eq);
		make_graph($eq);
	}
# 	print Dumper $eq->{graph};
# 	print Dumper $eq->{trees};
# 	print Dumper $eq;
}

# __END__
# print Dumper $equations_structures[1];

foreach (@equations_structures) {
	$_->{variables}->@* = find_variables($_);
	$_->{knowns}->@* = set_intersection( $_->{variables}, \@var_knowns);
	$_->{wants}->@*  = set_intersection( $_->{variables}, \@var_wants);
	$_->{unknowns}->@* = set_difference( $_->{variables}, \@var_knowns);
# 	print_equation_info($_);
}

if (@var_wants == 0 )
# 	and $equations_structures[0]->{trees}->{left_side}->{type} ne "variable")
	{die "no variable that need to be determined was given"}
# PROBLEM
# $ ./equations.pl 'x=4+5'
# no variable that need to be determined was given at ./equations.pl line 1431.
# OTHER LIIMIT CASE   5+5 = 5+5 print true  or 5+5=5+6  print false
#   a+b = c + d, a=1, b=2, c=3, d=4  --> no wanted var given, but number of var_knowns == number of vars in the equation
#    --> shoud print false
# something like x = y = z but not x = y = z = 1 

my ($wanted_var) = @var_wants;
my ($expanded_equation, $solution) = recursive_solve($wanted_var, @equations_structures);
if ($expanded_equation == 0) { die "can not solve system of equations\n"}



# NOT CURRENTLY POSSIBLE BECAUSE OF EXP LOG LOG10 SIN COS TAN
# my $infix = tree_to_infix($expanded_equation->{trees}->{right_side});
# my $infix_result = eval($infix);

my @postfix = tree_to_postfix($expanded_equation->{trees}->{right_side});
my $postfix_result = reverse_polish_calculator(@postfix);

# if ($infix_result ne $postfix_result) {
# 	print "infix calculations and postfix calculations differ";
# 	print "infix  calculation ---> $wanted_var = $infix_result";
# 	print "postix calculation ---> $wanted_var = $postfix_result";
# }

# START CLEAN OUPUT
print_equation($solution);
print_equation($expanded_equation);
print "$wanted_var = $postfix_result";
# print "$wanted_var = $infix_result";
# END CLEAN OUPUT

# print Dumper $solution->{trees};
# print Dumper $expanded_equation->{trees};

# print @postfix;

# make_overall_graph(@equations_structures);

$,="";


__END__

y=x^2
x=nth-root(y,2)



id 2 value x type variable
$VAR1 = {
          'right_side' => {
                            'left' => {
                                        'value' => 'y',
                                        'type' => 'variable',
                                        'id' => 0
                                      },
                            'right' => {
                                         'value' => 'x',
                                         'type' => 'variable',
                                         'id' => 2
                                       },
                            'type' => 'binary_op',
                            'value' => 'nth-root',
                            'id' => 1
                          },
          'left_side' => {
                           'type' => 'number',
                           'value' => '2',
                           'id' => 3
                         }
        };

value y type variable id 0
$VAR1 = {
          'right_side' => {
                            'id' => 1,
                            'right' => {
                                         'value' => 'y',
                                         'type' => 'variable',
                                         'id' => 0
                                       },
                            'value' => '^',
                            'type' => 'binary_op',
                            'left' => {
                                        'type' => 'number',
                                        'value' => '2',
                                        'id' => 3
                                      }
                          },
          'left_side' => {
                           'value' => 'x',
                           'type' => 'variable',
                           'id' => 2
                         }
        };





