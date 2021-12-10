#!/usr/bin/perl

# ./expression.pl '1+2*3-4'

use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
# $Data::Dumper::Indent = 1;

exit unless @ARGV;
my @tokens = split "", join("", @ARGV) =~ tr/ //dr;

my $pos = 0;

sub current {
	if (defined $tokens[$pos]) {
		return $tokens[$pos];
	}
	else {	# end of tokens
		return "";
	}
}

sub peek {
	if (defined $tokens[$pos+1]) {
		return $tokens[$pos+1];
	}
	else {	# end of tokens
		return "";
	}
}

sub take {
	my $token = shift;
	if (defined $token) {
		if ($token eq $tokens[$pos]) {
			return $tokens[$pos++];
		}
		else {
			die "wrong token";
		}
	}
	else {
		return $tokens[$pos++];
	}
}


# E -> T | T '+' E | T '-' E
# T -> F | F '*' T | F '/' T
# F -> number | '(' E ')'

sub parseE {
	my $left = parseT();
	my $right;

	if (current() eq "+") {
		take("+");
		$right = parseE();
		return { type => "+", left => $left, right => $right };
	}
	elsif (current() eq "-") {
		take("-");
		$right = parseE();
		return { type => "-", left => $left, right => $right };
	}
	else {
		return $left;
	}
}

sub parseT {
	my $left = parseF();
	my $right;

	if (current() eq "*") {
		take("*");
		$right = parseT();
		return { type => "*", left => $left, right => $right };
	}
	elsif (current() eq "/") {
		take("/");
		$right = parseT();
		return { type => "/", left => $left, right => $right };
	}
	else {
		return $left;
	}
}

sub parseF {
	my $expr;
	my $number;
	
	if (current() eq "(") {
		take("(");
		$expr = parseE();
		take(")");
		return $expr
	}
	else {
		$number = take();
		return { type => "number", value => $number };
	}
}

$\="\n";
print "TOKENS \"@tokens\"";

my $tree = parseE();

print Dumper $tree;

