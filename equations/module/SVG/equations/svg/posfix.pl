#!/usr/bin/perl

use strict;
use warnings;

$/=undef;
my $input;
my @tokens;

if (@ARGV) {
	if (-e $ARGV[0]) { $input = <ARGV>  }
	else             { $input = $ARGV[0]}
}
elsif (not -t STDIN) { $input = <STDIN> }
else                 { exit }

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
	my %associativity = ("*" => "left", "/" => "left", "+" => "left", "-" => "left");
	foreach $token (@_){
		if ($token =~ /\d|[a-zA-Z]/) {		# NUMBER or VARIABLE
			push @queue, $token;
		}
# 		elsif ($token is a function) {		# FUNCTION
# 			push @stack, $token;
# 		}
		elsif ($token =~ m|[-+*/]|) {		# OPERATOR
			while (($#stack >= 0)
				  and (( $precedence{$token} < $precedence{$stack[-1]} )
					  or (  $precedence{$token} == $precedence{$stack[-1]} and $associativity{$token} eq "left"  ))
				  and ( $stack[-1] ne "("  )) {
# 			while (($#stack >= 0) 
# 				  and ( $precedence{$token} < $precedence{$stack[-1]} )
# 				  and ( $stack[-1] ne "(" ) ) {

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


my @infix   = tokenize($input);
my @postfix = infix_to_postfix(@infix);

$\="\n";

print join " ", @postfix;

