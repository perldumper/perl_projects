
package Equation::Parser;
use strict;
use warnings;
use Operations;

our %precedence;       *precedence        = *Operations::precedence{HASH};
our %left_associative; *left_associative  = *Operations::left_associative{HASH};

use Exporter 'import';
our @EXPORT = "parse_equation";
our @EXPORT_OK = "parse_expression";

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

		elsif ($expression =~ m/\G(\d+\.?\d*)/gc)           { push @tokens, $1  }
		elsif ($expression =~ m/\G([a-zA-Z][a-zA-Z0-9]*)/gc){ push @tokens, $1  }

		else { $end = 1 }
	}
# 	print "TOKENS @tokens";
	return @tokens;
}

# reduce 5--5 into 5+5, 5+-+5 into 5-5, 5---5 into 5, etc..
sub simplify_signs {
	my @tokens = @_;

	for (my $i=0; $i < $#tokens; $i++) {# avoid testing for definedness, expressions shouldn't finish by + or -

		if ($tokens[$i] eq "+") {
			if ($tokens[$i+1] eq "+" or $tokens[$i+1] eq "-") {
				splice @tokens, $i, 1;
				redo;
			}
		}
		elsif ($tokens[$i] eq "-") {
			if ($tokens[$i+1] eq "+") {
				splice @tokens, $i+1, 1;
				redo;
			}
			elsif ($tokens[$i+1] eq "-") {
				$tokens[$i] = "+";
				splice @tokens, $i+1, 1;
				redo;
			}
		}
	}
# 	print "TOKENS @tokens";
	return @tokens;
}


# Shunting-Yard algorithm
# https://en.wikipedia.org/wiki/Shunting-yard_algorithm (complete algorithm here)
# https://www.youtube.com/watch?v=Wz85Hiwi5MY           (not complete algorithm)
sub infix_to_postfix {
# 	my @tokens = @_;
# 	my @stack;
# 	my @queue;
	our @tokens = @_;
	our @stack  = ();
	our @queue  = ();
	my $token;
	my $op;

# 	print "infix_to_postfix";
# 	print "TOKENS @tokens";

# 	print "-" x 40;
# 	print "LEFT_ASSOCIATIVE";
# 	print "KEY $_\tVALUE $left_associative{$_}" for keys %left_associative;
# 	print %left_associative;
# 	print "-" x 40;
# 	print "PRECEDENCE";
# 	print "KEY $_\tVALUE $precedence{$_}" for keys %precedence;
# 	print %precedence;
# 	print "-" x 40;


# 	printf "     %5s     %-10s%10s\n", "STACK", "QUEUE", "TOKENS" if $debug;
	sub print_state { printf "     %-10s%-14s%-20s\n", join("", @stack), join("",@queue), join("",@tokens) }
# 	print_state() if $debug;

# 	print "START WHILE LOOP";
	while ( defined ($token = shift @tokens) ) {
# 		print "TOKEN \"$token\"";
		if ($token =~ m/^(?:sqrt|exp|ln|log|log10|exp10|pow2|nth-root|arcsin|arccos|arctan|sin|cos|tan)$/ ) { # FUNCTION
			push @stack, $token;
		}

		elsif ($token =~ m/\d|[a-zA-Z]/) {	# NUMBER or VARIABLE
			push @queue, $token;
		}

		elsif ($token =~ m|^[-+*/^%]$|) {		# OPERATOR		# shoud infix nth-root be included ??
# 			if (not exists $left_associative{$token}) {
# 			if (not exists $precedence{$token}) {
# 				print "-" x 40;
# 				print "key \"$token\" does not exists";
# 				print "LEFT_ASSOCIATIVE";
# 				print "KEY $_\tVALUE$left_associative{$_}" for keys %left_associative;
# 				print "-" x 40;
# 				
# 			}
# 			elsif (not defined $left_associative{$token}) {
# 				print "-" x 40;
# 				print "value of key \"$token\" is not defined";
# 				print "LEFT_ASSOCIATIVE";
# 				print "KEY $_\tVALUE$left_associative{$_}" for keys %left_associative;
# 				print "-" x 40;
# 			}

			while (($#stack >= 0)
				  and (( $precedence{$token} < $precedence{$stack[-1]} )
					  or (  $precedence{$token} == $precedence{$stack[-1]} and $left_associative{$token} ))
				  and ( $stack[-1] ne "("  )) {

				push @queue, pop @stack;
# 				print_state() if $debug;
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
# 				print_state() if $debug;
			}
			if (@stack) {
				if ( $stack[-1] =~ m/^(?:sqrt|exp|ln|log|log10|exp10|pow2|nth-root|arcsin|arccos|arctan|sin|cos|tan)$/ ) {
					push @queue, pop @stack;	# function
# 					print_state() if $debug;
				}
			}
		}
	} # end while

# 	print "END WHILE LOOP";

# 	print_state() if $debug;

	while (defined ($op = pop @stack)) {
		push @queue, $op;
# 		print_state() if $debug;
	}
# 	print_state() if $debug;
# 	print "POSTFIX @queue";
	return @queue;
}

# https://en.wikipedia.org/wiki/Binary_expression_tree#Construction_of_an_expression_tree
sub postfix_to_tree {
	my @queue = @_;
	my @stack;
	my $left;
	my $right;
	my $argument;
	while (defined (my $symbol = shift @queue) ) {
		if ($symbol =~ m/\d/) {											# NUMBER
			push @stack, {type=> "number", value=> $symbol};
		}
		elsif ($symbol =~ m|^[-+/*^%]$|) {								# OPERATOR
			$right = pop @stack;
			$left  = pop @stack;
			push @stack, {type=> "binary_op", value=> $symbol, left=> $left, right=> $right};
# 			$stack[-1]->{left}->{parent} = $stack[-1];
# 			$stack[-1]->{right}->{parent} = $stack[-1];
		}
		elsif ($symbol =~ m/^(?:sqrt|exp|exp10|ln|log|log10|pow2|arcsin|arccos|arctan|sin|cos|tan)$/) {	# FUNCTION
			$argument = pop @stack;
			push @stack, {type=> "unary_op", value=> $symbol, operand=> $argument};
# 			$stack[-1]->{operand}->{parent} = $stack[-1];
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
# 	print Dumper @stack;
	return pop @stack;
}

sub parse_equation {
	my $equation_string = shift;
	my ($left_expression, $right_expression) = split /=/, $equation_string;

	my @left_infix   = simplify_signs(tokenize($left_expression));
	my @left_postfix = infix_to_postfix(@left_infix);
	my $left_tree    = postfix_to_tree(@left_postfix);

	my @right_infix   = simplify_signs(tokenize($right_expression));
	my @right_postfix = infix_to_postfix(@right_infix);
	my $right_tree    = postfix_to_tree(@right_postfix);

	return {left_side => $left_tree, right_side=> $right_tree};
}

sub parse_expression {
	my $expression_string = shift;

	my @infix   = simplify_signs(tokenize($expression_string));
	my @postfix = infix_to_postfix(@infix);
	my $tree    = postfix_to_tree(@postfix);
    return $tree;
}



1;
__END__

