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

my @queue = @tokens;
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
$\="\n";
print pop @stack;

