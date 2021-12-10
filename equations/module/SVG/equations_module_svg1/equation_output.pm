#!/usr/bin/perl

use strict;
use warnings;

package equation_output;

use Exporter 'import';
our @EXPORT = qw(
		postfix_to_infix
		reverse_polish_calculator
		tree_to_infix
		tree_to_postfix
		print_equation
		print_equation_info
		stringify
);

use maths_operations;
use Math::Trig;
use finding_things;

our %precedence;
our %left_associative;
our %right_associative;
our %inverse;

*precedence        = *main::precedence;
*left_associative  = *main::left_associative;
*right_associative = *main::right_associative;
*inverse           = *main::inverse;


##########################
#    EQUATION  OUTPUT    #
##########################


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
			unshift @operand, pop @stack;
			if (@stack) {
				until ($stack[-1] =~ m/\d|[a-zA-Z]/ or $stack[-1] eq ")" ) {
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
			if (@stack) {
				if ($stack[-1] =~ m/^(?:sqrt|exp|exp10|ln|log|log10|pow2|nth-root|arcsin|arccos|arctan|sin|cos|tan)$/) {
					unshift @operand, pop @stack;
				}
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

	while ( defined ($token = shift @queue)) {

# 		print "TOKEN $token\n";

		if ($token =~ m#^(?:[-+/*%^]|nth-root)$#) {

			@right = get_operand();
			@left  = get_operand();
# 			print "RIGHT @right\n";
# 			print "LEFT @left\n";

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

			if ($token eq "nth-root") {
				if (@right == 1 and $right[0] == 2) {
# 					push @stack, "sqrt", "(", @left, ")";				# sqrt(x)
					push @stack, "(", "sqrt", "(", @left, ")", ")";				# sqrt(x)
				}
				else {
# 					push @stack, $token, "(", @right, ",", @left, ")";	# nth-root(3,x)
					push @stack, "(",  @left, "^", "1", "/", @right, ")";			# x^3
				}
			}
			else {
				push @stack, "(", @left, $token, @right, ")";
			}
		}
		elsif ($token =~ m/^(?:sqrt|exp|exp10|ln|log|log10|pow2|arcsin|arccos|arctan|sin|cos|tan)$/ ) {
# 			print "STACK @stack\n";
			@operand = get_operand();
			if ($operand[0] eq "(") {
				@operand = remove_outer_parens(@operand);
			}

# 			print "OPERAND @operand\n";
# 			push @stack, $token, "(", @operand, ")";
			push @stack, "(", $token, "(", @operand, ")", ")";
# 			print "STACK @stack\n";
		}
		elsif ($token =~ m/\d|[a-zA-Z]/) {
			push @stack, $token;
		}
	}

# 	print "STACK @stack\n";
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

	while (defined ($symbol = shift @queue)) {
# 		print "STACK @stack\tQUEUE @queue";
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
				$right = pop @stack;		# maybe the reverse is better
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

# in-order tree traversal, to obtain infix expression
sub tree_to_infix {
	my $node = shift;
	my $infix = "";
	if ($node->{type} eq "binary_op") {
		$infix .= "(";
		$infix .= tree_to_infix($node->{left});
		$infix .= $node->{value};
		$infix .= tree_to_infix($node->{right});
		$infix .= ")";
		return $infix;
	}
	elsif ($node->{type} eq "unary_op") {
		$infix .= "(";
		$infix .= $node->{value};
		$infix .= $node->{operand};
		$infix .= ")";
		return $infix;
	}
	else {
		return $node->{value};
	}
}

# post-order tree traversal, to obtain infix expression
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

sub print_equation {
	my $equation = shift;
	local $\="";
	local $,="";
 	print postfix_to_infix( tree_to_postfix($equation->{trees}->{left_side}) );
	print " = ";
 	print postfix_to_infix( tree_to_postfix($equation->{trees}->{right_side}) );
	print "\n";
}

sub stringify {
	my $equation = shift;
	join "", postfix_to_infix( tree_to_postfix($equation->{trees}->{left_side}) ),
	" = ",
 	postfix_to_infix( tree_to_postfix($equation->{trees}->{right_side}) );
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

1;

