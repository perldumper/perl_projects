
package equation_output;
use strict;
use warnings;

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
use finding_things;
use Math::Trig;
use Data::Dumper;

our %precedence;
our %left_associative;
our %right_associative;
# our %inverse;

*precedence        = *main::precedence;
*left_associative  = *main::left_associative;
*right_associative = *main::right_associative;
# *inverse           = *main::inverse;


##########################
#    EQUATION  OUTPUT    #
##########################

sub can_remove_outer_parens_operand {
	my $node = shift;
	if (exists $node->{parent}) {
		if ($node->{parent}->{type} eq "binary_op") {
			if ($node->{parent}->{left} == $node) {	# node is the left operand
				if (  (not $left_associative{ $node->{parent}->{value} }
                        and $precedence{ $node->{value} } > $precedence{ $node->{parent}->{value} })
                   or ( $left_associative{ $node->{parent}->{value} }
                        and $precedence{ $node->{value} } >= $precedence{ $node->{parent}->{value} } ))
				{
					return 1
				}
				else {
					return 0
				}
			}
			elsif ($node->{parent}->{right} == $node) { # node is the right operand
				if (  (not $right_associative{ $node->{parent}->{value} }
                        and $precedence{ $node->{value} } > $precedence{ $node->{parent}->{value} })
                   or ( $right_associative{ $node->{parent}->{value} }
                        and $precedence{ $node->{value} } >= $precedence{ $node->{parent}->{value} } ))
				{
					return 1
				}
				else {
					return 0
				}
			}
			else {
				die "node is neither the left nor right subtree of its parent, which is a binary_op\n";
			}
		}
		else {	# unary_op or top of the tree
			return 1
		}
	}
	else {	# top of the tree (or parent not added / updated by isolate or other function)
		return 1
	}
}

# make option to put parentheses around - and / even if it is not necessary 3-2-1 12/4/2
sub tree_to_infix {
	my $node = shift;
	my $infix = "";
	if ($node->{type} eq "binary_op") {
		if ($node->{value} eq "nth-root") {
			if ($node->{right}->{type} eq "number" and $node->{right}->{value} == 2) {		# sqrt(x)
				$infix .= "sqrt(";
				$infix .= tree_to_infix($node->{left});
				$infix .= ")";
			}
			else {																			# nth-root(3,x)
				$infix .= tree_to_infix($node->{left});
				$infix .= "^(1/";
				$infix .= tree_to_infix($node->{right});
				$infix .= ")";
			}
		}
		else {
			if (can_remove_outer_parens_operand($node)) {	# because precedence and assoc of outer operator relative to 
															# precedence and associativity of operator inside operand allows it
				$infix .= tree_to_infix($node->{left});
				$infix .= $node->{value};
				$infix .= tree_to_infix($node->{right});
			}
			else {
				$infix .= "(";
				$infix .= tree_to_infix($node->{left});
				$infix .= $node->{value};
				$infix .= tree_to_infix($node->{right});
				$infix .= ")";
			}
		}
		return $infix;
	}
	elsif ($node->{type} eq "unary_op") {
		$infix .= $node->{value};
		$infix .= "(";
		$infix .= tree_to_infix($node->{operand});
		$infix .= ")";
		return $infix;
	}
	else {
		return $node->{value};
	}
}


# postfix stack evaluator
# https://www.youtube.com/watch?v=bebqXO8H4eA
sub reverse_polish_calculator {
	my @queue = @_;
	my @stack;
	my ($left, $right);
	my $symbol;
# 	print "QUEUE @queue";

	while (defined ($symbol = shift @queue)) {
		print "STACK @stack\tQUEUE @queue";
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
			elsif ($symbol eq "ln"   ) {
				die "ln is defined on reals strictly potive\n$stack[-1] <= 0\n" if $stack[-1] <= 0;
				push @stack, log pop @stack;
			}
			elsif ($symbol eq "log"  ) {
				die "ln is defined on strictly positive reals : $stack[-1] <= 0\n" if $stack[-1] <= 0;
				push @stack, log pop @stack;
			}
			elsif ($symbol eq "log10") {
				$right = pop @stack;
				die "ln is defined on strictly positive reals : $right <= 0\n" if $right <= 0;
				push @stack, (log $right) / (log 10)
			}
			elsif ($symbol eq "sqrt" ) {
				die "sqrt is defined on positive reals : $stack[-1] <= 0\n" if $stack[-1] < 0;
				push @stack, sqrt pop @stack;
			}
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
	set_parent($equation->{trees}->{left_side});
	set_parent($equation->{trees}->{right_side});
 	print tree_to_infix($equation->{trees}->{left_side});
	print " = ";
 	print tree_to_infix($equation->{trees}->{right_side});
	print "\n";
}

sub stringify {
	my $equation = shift;
	set_parent($equation->{trees}->{left_side});
	set_parent($equation->{trees}->{right_side});
	join "", tree_to_infix($equation->{trees}->{left_side}),
	" = ",
 	tree_to_infix($equation->{trees}->{right_side});
}


sub print_equation_info {
	my $equation = shift;
	local $,=" ";
	local $\="\n";
	print "EQUATION\t",  $equation->{string};
	print "VARIABLES\t", sort $equation->{variables}->@*;
	print "WANTS\t\t",   sort $equation->{wants}->@*;
	print "KNOWNS\t\t",  sort $equation->{knowns}->@*;
	print "UNKNOWNS\t",  sort $equation->{unknowns}->@*;
	print "";
}

1;

