#!/usr/bin/perl

use strict;
use warnings;


##########################
#    MATHS OPERATIONS    #
##########################

# my %precedence = ("^" => 3, "*" => 2, "/" => 2, "+" => 1, "-" => 1, "(" => 0, ")" => 0);
# my %precedence = (exp=>0, log=>0, log10=>0, sin=>0, cos=>0, tan=>0, "^" => 3, "*" => 2, "/" => 2, "+" => 1, "-" => 1, "(" => 0, ")" => 0);
my %precedence = (
	exp   => 4,
	ln    => 4,
	log   => 4,
	log10 => 4,
	sin   => 4,
	cos   => 4,
	tan   => 4,
	"^"   => 3,
	"*"   => 2,
	"/"   => 2,
	"+"   => 1,
	"-"   => 1,
	"("   => 0,
	")"   => 0,
# 	"("   => 5,
# 	")"   => 5,
);

# my %left_associative = ( exp=>0, log=>0, log10=>0, sin=>0, cos=>0, tan=>0, "^" => 0, "*" => 1, "/" => 1, "+" => 1, "-" => 1, "%"=> 1);
my %left_associative = ( exp=>1, log=>1, log10=>1, sin=>1, cos=>1, tan=>1, "^" => 0, "*" => 1, "/" => 1, "+" => 1, "-" => 1, "%"=> 1);


my %right_associative = ( "^" => 1, "*" => 1, "/" => 0, "+" => 1, "-" => 0, "%"=> 0);


$/=undef;
$\="\n";
my $input;
my @tokens;

my $debug;

if (@ARGV) {
	if ($ARGV[0] eq "debug") { shift; $debug = 1 }
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
	my @tokens = @_;
	my @stack;
	my @queue;
	my $token;
	my $op;

	printf "     %5s     %-10s%10s\n", "STACK", "QUEUE", "TOKENS" if $debug;
	printf "     %-10s%-14s%-20s\n", join("", @stack), join("",@queue), join("",@tokens) if $debug;

	while ( $token = shift @tokens) {
		printf "     %-10s%-14s%-20s\n", join("", @stack), join("",@queue), join("",@tokens) if $debug;
		if ($token =~ m/^(?:exp|ln|log|log10|sin|cos|tan)$/ ) { # FUNCTION
			push @stack, $token;
		}

		elsif ($token =~ /\d|[a-zA-Z]/) {	# NUMBER or VARIABLE
			push @queue, $token;
		}

		elsif ($token =~ m|[-+*/]|) {		# OPERATOR
			while (($#stack >= 0)
				  and (( $precedence{$token} < $precedence{$stack[-1]} )
					  or (  $precedence{$token} == $precedence{$stack[-1]} and $left_associative{$token} ))
				  and ( $stack[-1] ne "("  )) {

				push @queue, pop @stack;
				printf "     %-10s%-14s%-20s\n", join("", @stack), join("",@queue), join("",@tokens) if $debug;
			}
			push @stack, $token;
		}
		elsif ( $token eq "(" ) {			# OPENING PARENTHESIS
			push @stack, $token;
		}
		elsif ( $token eq ")" ) {			# CLOSING PARENTHESIS
			while ($stack[-1] ne "(") {
				push @queue, pop @stack;
				printf "     %-10s%-14s%-20s\n", join("", @stack), join("",@queue), join("",@tokens) if $debug;
			}
			#/* If the stack runs out without finding a left parenthesis, then there are mismatched parentheses. */
			if ( $stack[-1] eq "(" ) {
				pop @stack;					# operator
				printf "     %-10s%-14s%-20s\n", join("", @stack), join("",@queue), join("",@tokens) if $debug;
			}
			if (@stack) {
				if ( $stack[-1] =~ m/^(?:exp|ln|log|log10|sin|cos|tan)$/ ) {
					push @queue, pop @stack;	# function
					printf "     %-10s%-14s%-20s\n", join("", @stack), join("",@queue), join("",@tokens) if $debug;
				}
			}
		}
	} # end while

	printf "     %-10s%-14s%-20s\n", join("", @stack), join("",@queue), join("",@tokens) if $debug;

	while ($op = pop @stack){
		push @queue, $op;
		printf "     %-10s%-14s%-20s\n", join("", @stack), join("",@queue), join("",@tokens) if $debug;
	}
	printf "     %-10s%-14s%-20s\n", join("", @stack), join("",@queue), join("",@tokens) if $debug;
	return @queue;
}




my @infix   = tokenize($input);
my @postfix = infix_to_postfix(@infix);

$\="\n";

print join "", @postfix;

