#!/usr/bin/perl

use strict;
use warnings;

$/=undef;
my $expression;

if (@ARGV) {
	if (-e $ARGV[0]) { $expression = <ARGV>  }
	else             { $expression = $ARGV[0]}
}
elsif (not -t STDIN) { $expression = <STDIN> }
else                 { exit }

$,="";
$\="\n";

sub tokenize {
	my $expression = shift;
	my @tokens;
	my $end = 0;
	while (not $end) {
		if    ($expression =~ m/\G /gc)                     { 1; }
		elsif ($expression =~ m/\G(\d+)/gc)                 { push @tokens, $1  }
		elsif ($expression =~ m/\G([a-zA-Z][a-zA-Z0-9]*)/gc){ push @tokens, $1  }

		elsif ($expression =~ m/\G\+/gc)                    { push @tokens, "+" }
		elsif ($expression =~ m/\G\-/gc)                    { push @tokens, "-" }
		elsif ($expression =~ m/\G\*/gc)                    { push @tokens, "*" }
		elsif ($expression =~ m/\G\//gc)                    { push @tokens, "/" }
		elsif ($expression =~ m/\G\^/gc)                    { push @tokens, "^" }
		elsif ($expression =~ m/\G\%/gc)                    { push @tokens, "%" }

		elsif ($expression =~ m/\G\(/gc)                    { push @tokens, "(" }
		elsif ($expression =~ m/\G\)/gc)                    { push @tokens, ")" }

		else { $end = 1 }
	}
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
	our @stack;
	our @queue;
	my $token;
	my $op;
	our %precedence = ("^" => 3, "*" => 2, "/" => 2, "+" => 1, "-" => 1, "(" => 0, ")" => 0);
# 	my %associativity = ("*" => "left", "/" => "left", "+" => "left", "-" => "left", "^" => "right", "%" => "right");
# 	my %associativity = ("*" => "left", "/" => "left", "+" => "left", "-" => "left", "^" => "right", "%" => "left");
	our %left_assoc = ("*" => 1, "/" => 1, "+" => 1, "-" => 1, "^" => 0, "%" => 1);
	our %right_assoc = ("*" => 1, "/" => 0, "+" => 1, "-" => 0, "^" => 1, "%" => 0);

	printf "     %5s     %-10s%10s\n", "STACK", "QUEUE", "TOKENS" if defined $ARGV[1];
	sub print_state() {
		printf "     %-10s%-14s%-20s\n", join("", @stack), join("",@queue), join("",@tokens) if defined $ARGV[1];
	}
	print_state();

# 	foreach $token (@tokens) {
	while ( $token = shift @tokens) {
		if ($token =~ /\d|[a-zA-Z]/) {		# NUMBER or VARIABLE
			push @queue, $token;
			print_state();
		}
# 		elsif ($token is a function) {		# FUNCTION
# 			push @stack, $token;
# 		}
		elsif ($token =~ m|[-+*/^%]|) {		# OPERATOR
			while (($#stack >= 0)
				  and (( $precedence{$token} < $precedence{$stack[-1]} )
					  or (  $precedence{$token} == $precedence{$stack[-1]} and $left_assoc{$token} ))
				  and ( $stack[-1] ne "("  )) {

				push @queue, pop @stack;
				print_state();
			}
			push @stack, $token;
			print_state();
		}
		elsif ( $token eq "(" ) {			# OPENING PARENTHESIS
			push @stack, $token;
			print_state();
		}
		elsif ( $token eq ")" ) {			# CLOSING PARENTHESIS
			while ($stack[-1] ne "(") {
				push @queue, pop @stack;
				print_state();
			}
			#/* If the stack runs out without finding a left parenthesis, then there are mismatched parentheses. */
			if ( $stack[-1] eq "(" ) {
				pop @stack;					# operator
				print_state();
			}
# 			if ( $stack[-1] is a function ) {
# 				push @queue, pop @stack;	# function
# 			}
		}
	} # end foreach
	while ($op = pop @stack){
		push @queue, $op;
		print_state();
	}
	return @queue;
	print_state();
}

sub postfix_to_infix {
	our @queue = @_;
	our @stack;
	my $token;
	my @right;
	my @left;
	my $level;

	our %precedence = ("(" => 2, ")" => 2, "*" => 1, "/" => 1, "+" => 0, "-" => 0);
	our %left_assoc = ("*" => 1, "/" => 1, "+" => 1, "-" => 1, "^" => 0, "%" => 1);
	our %right_assoc = ("*" => 1, "/" => 0, "+" => 1, "-" => 0, "^" => 1, "%" => 0);

	$,=" ";
	$"=" ";
	$\="\n";

	sub get_operand {
		my @operand;
		my $level;
		if ($stack[-1] =~ m/\d/) {

			unshift @operand, pop @stack;
			if (@stack) {
				until ($stack[-1] =~ m/\d/ or $stack[-1] eq ")" ) {
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
		
		my $EXT_OP_right_assoc = $right_assoc{ $external_op };
		my $EXT_OP_preced         = $precedence{ $external_op };
		my $minimum_OP_preced_OPERAND;

		if (@right == 1) {												# number
			if ($right[0] =~ m/\d/) {
				return 0;	# bare number, no parentheses to remove
			}
		}
		elsif (@right == 3) {											# number OP number / ( number )
			if ($right[0] eq "(" and $right[1] =~ m/\d/ ) {				# ( number )
				return 1;
			}
			elsif ($right[0] =~ /\d/ and $right[1] =~ m|^[-+/*%^]$| ) {	# number OP number
				
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
		
		my $EXT_OP_left_assoc = $left_assoc{ $external_op };
		my $EXT_OP_preced     = $precedence{ $external_op };
		my $minimum_OP_preced_OPERAND;

		if (@left == 1) {												# number
			if ($left[0] =~ m/\d/) {
				return 0;
			}
		}
		elsif (@left == 3) {											# number OP number / ( number )
			if ($left[0] eq "(" and $left[1] =~ m/\d/ ) {				# ( number )
				return 1;
			}
			elsif ($left[0] =~ /\d/ and $left[1] =~ m|^[-+/*%^]$| ) {	# number OP number
				
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

		if ($token =~ m|^[-+/*%^]$|) {

			@right = get_operand();
			@left  = get_operand();

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
			push @stack, "(", @left, $token, @right, ")";
		}
		elsif ($token =~ m/\d/) {
			push @stack, $token;
		}
	}

	return remove_outer_parens(@stack);
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

$,=" ";
$\="\n";


my @infix;
my @postfix;


# print $expression;

@infix   = tokenize($expression);
print @infix;
# print grep { !/\d/ } @infix;

@postfix = infix_to_postfix(@infix);
print "=" x 40 if defined $ARGV[1];
print @postfix;

@infix = ();
@infix = postfix_to_infix(@postfix);

print @infix;

##################




# print reverse_polish_calculator(@postfix);
# print reverse_polish_calculator(reverse @postfix);




__END__


- the order of the numbers isn't changed between infix to postfix











