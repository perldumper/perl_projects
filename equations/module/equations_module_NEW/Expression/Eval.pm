
package Expression::Eval;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
		reverse_polish_calculator
		print_equation_info
);

use Math::Trig;
use Data::Dumper;

#############
# make subroutine from expression
#
#
#
#
#
#
#
#
###############


# METHODS OF EVALUATION
# tree_to_postfix  then  reverse_polish_calculator
# tree_to_infix    then  eval (perl builtin)


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
            print Dumper \$left;
            print "-"x40;
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


1;
__END__

