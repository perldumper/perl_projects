#!/usr/bin/perl

use strict;
use warnings;

my $program;
$/=undef;

if (@ARGV) {
	if (-e $ARGV[0]) { $program = <ARGV>  }
	else             { $program = $ARGV[0]}
}
elsif (not -t STDIN) { $program = <STDIN> }
else                 {exit}

my $end = 0;
my @tokens;

while(not $end){

	if($program =~ m/\G /gsc){ 1; }
	elsif($program =~ m/\G(\d+)/gsc)      {push @tokens, {type=>"number",       value=>$1} }
	elsif($program =~ m/\G([a-zA-Z]+)/gsc){push @tokens, {type=>"variable",     value=>$1} }

	elsif($program =~ m/\G(\+)/gsc)       {push @tokens, {type=>"+",      value=>"+"} }
	elsif($program =~ m/\G(\-)/gsc)       {push @tokens, {type=>"-",      value=>"-"} }
	elsif($program =~ m/\G(\*)/gsc)       {push @tokens, {type=>"*",      value=>"*"} }
	elsif($program =~ m/\G(\/)/gsc)       {push @tokens, {type=>"/",      value=>"/"} }

	elsif($program =~ m/\G(\()/gsc)       {push @tokens, {type=>"(",    value=>"("} }
	elsif($program =~ m/\G(\))/gsc)       {push @tokens, {type=>")",    value=>")"} }

#	elsif($program =~ m/\G(\+)/gsc)       {push @tokens, {type=>"plus",         value=>"+"} }
#	elsif($program =~ m/\G(\-)/gsc)       {push @tokens, {type=>"minus",        value=>"-"} }
#	elsif($program =~ m/\G(\*)/gsc)       {push @tokens, {type=>"multiply",     value=>"*"} }
#	elsif($program =~ m/\G(\/)/gsc)       {push @tokens, {type=>"divide",       value=>"/"} }

#	elsif($program =~ m/\G(\()/gsc)       {push @tokens, {type=>"parenopen",    value=>"("} }
#	elsif($program =~ m/\G(\))/gsc)       {push @tokens, {type=>"parenclose",   value=>")"} }

	else {$end = 1}
}

$\="\n";
printf "%-12s %s\n", $_->{type}, $_->{value} foreach @tokens;

my $token;
my @stack;

while ($token = shift @tokens) {
	print $token;
}

my %expr = ();
my %number = ();
my %variable = ();


#expr
#	:	number
#	|	variable
#	|	'(' expr ')'					# grouping with parentheses
#	|	<assoc=right> expr '^' expr		# exponentiation
#	|	('+' | '-') expr				# unary plus/minus
#	|	expr ('/' | '*') expr			# explicit division/multiplication
#	|	expr ('+' | '-') expr			# addition/subtraction

__END__

#expr
#	:	number
#	|	variable
#	|	'(' expr ')'					# grouping with parentheses
#	|	<assoc=right> expr '^' expr		# exponentiation
#	|	('+' | '-') expr				# unary plus/minus
#	|	expr ('/' | '*') expr			# explicit division/multiplication
#	|	expr ('+' | '-') expr			# addition/subtraction


############################################################################

#expr
#	:	number
#	|	variable
#	|	'(' expr ')'					# grouping with parentheses
#	|	<assoc=right> expr '^' expr		# exponentiation
#	|	('+' | '-') expr				# unary plus/minus
#	|	expr ('/' | '*') expr			# explicit division/multiplication
#	|	expr ('+' | '-') expr			# addition/subtraction


#expr
#	:	number
#	|	variable
#	|	'(' expr ')'					# grouping with parentheses
#	|	'+' expr
#	|	'-' expr						# unary plus/minus

#	|	expr '^' expr					# exponentiation

expr -> expr ^ expr


#	|	expr '*' expr					# explicit multiplication

#	|	expr '/' expr					# explicit division

#	|	expr '+' expr					# addition

#	|	expr '-' expr					# subtraction













