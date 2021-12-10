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

#while(not $end){

#	if($program =~ m/\G /gsc){ 1; }
#	elsif($program =~ m/\G(\d+)/gsc){push @tokens, {type=>"number",   value=>$1} }

#	elsif($program =~ m/\G(\+)/gsc) {push @tokens, {type=>"plus",     value=>"+"} }
#	elsif($program =~ m/\G(\-)/gsc) {push @tokens, {type=>"minus",    value=>"-"} }
#	elsif($program =~ m/\G(\*)/gsc) {push @tokens, {type=>"multiply", value=>"*"} }
#	elsif($program =~ m/\G(\/)/gsc) {push @tokens, {type=>"divide",   value=>"/"} }

#	elsif($program =~ m/\G(\()/gsc) {push @tokens, {type=>"parenopen",    value=>"("} }
#	elsif($program =~ m/\G(\))/gsc) {push @tokens, {type=>"parenclose",   value=>")"} }

#	else {$end = 1}
#}

#$\="\n";
#print "$_->{type}\t$_->{value}" foreach @tokens;
#printf "%-12s %s\n", $_->{type}, $_->{value} foreach @tokens;
#my @infix = map { $_->{value} } @tokens;


while(not $end){

	if($program =~ m/\G /gsc){ 1; }
	elsif($program =~ m/\G(\d+)/gsc){ push @tokens, $1 }

	elsif($program =~ m/\G(\+)/gsc) { push @tokens, "+" }
	elsif($program =~ m/\G(\-)/gsc) { push @tokens, "-" }
	elsif($program =~ m/\G(\*)/gsc) { push @tokens, "*" }
	elsif($program =~ m/\G(\/)/gsc) { push @tokens, "/" }

	elsif($program =~ m/\G(\()/gsc) { push @tokens, "(" }
	elsif($program =~ m/\G(\))/gsc) { push @tokens, ")" }

	else {$end = 1}
}

$\="\n";
$,="\n";
#print @tokens;

## EVALUTATION
# SOLUTION 1 recursive descent evaluation ?
# SOLUTION 2 infix -> [Shunting Yard algorithm] -> postfix -> Reverse Polish Calculator / postfix stack evaluator
# SOLUTION 3 operator precedence parser --> AST --> post-order traversal of tree --> postfix

# WRONG !!!!
#sub infix_to_postfix {
#	#	Shunting Yard algorithm
#	my @stack; # push / pop
#	my @queue; # push / shift  -->  enqueue / dequeue
#	my %precedence = ("(" => 2, ")" => 2, "*" => 1, "/" => 1, "+" => 0, "-" => 0);
#	my $op;

#	foreach(@_){
#		if ($_ =~ /\d/){			# NUMBER
#			push @queue, $_;
#		}
#		elsif ($_ =~ m|[-+*/]|) {	# OPERATOR
#			if ($#stack >= 0 and $stack[$#stack] ne "(" ) {		# stack non empty and top of stack is not "("
#				if ( $precedence{$_} < $precedence{$stack[$#stack]} ) {	# precedence OP at top of stack superior to OP incoming
#					push @queue, pop @stack;
#					push @stack, $_;
#				}
#				else {													# precedence OP at top of stack <= to OP incoming
#					push @stack, $_;
#				}
#			}
#			else {												# stack empty or top of stack is "("
#				push @stack, $_;
#			}
#		}
#		elsif ($_ eq "(") {			# OPENING PARENTHESIS
#			push @stack, $_;
#		}
#		elsif ($_ eq ")") {			# CLOSING PARENTHESIS
#			while ($op = pop(@stack), $op ne "("){
#				push @queue, $op;
#			}
#		}
#	}

#	while ($op = pop @stack){
#		push @queue, $op;
#	}
#	return @queue;
#}


sub infix_to_postfix {
	my @stack;
	my @queue;
	my $token;
	my $op;
	my %precedence = ("(" => 2, ")" => 2, "*" => 1, "/" => 1, "+" => 0, "-" => 0);
	my %associativity = ("*" => "both?", "/" => "", "+" => "both?", "-" => "");
	foreach $token (@_){
		if ($token =~ /\d/) {				# NUMBER
			push @queue, $token;
		}
#		elsif ($token is a function) {		# FUNCTION
#			push @stack, $token;
#		}
		elsif ($token =~ m|[-+*/]|) {		# OPERATOR
#			while (($#stack >= 0)
#				  and (( $precedence{$token} < $precedence{$stack[$#stack]} )
#					  or (  $precedence{$token} == $precedence{$stack[$#stack]} and $associativity{$token} eq "left"  ))
#				  and ( $stack[$#stack] ne "("  )) {
			while (($#stack >= 0) 
				  and ( $precedence{$token} < $precedence{$stack[$#stack]} )
				  and ( $stack[$#stack] ne "(" ) ) {

				push @queue, pop @stack;
			}
			push @stack, $token;
		}
		elsif ( $token eq "(" ) {			# OPENING PARENTHESIS
			push @stack, $token;
		}
		elsif ( $token eq ")" ) {			# CLOSING PARENTHESIS
			while ($stack[$#stack] ne "(") {
				push @queue, pop @stack;
			}
			#/* If the stack runs out without finding a left parenthesis, then there are mismatched parentheses. */
			if ( $stack[$#stack] eq "(" ) {
				pop @stack;					# operator
			}
#			if ( $stack[$#] is a function ) {
#				push @queue, pop @stack;	# function
#			}
		}
	} # end foreach
	while ($op = pop @stack){
		push @queue, $op;
	}
	return @queue;
}



# postfix stack evaluator
sub reverse_polish_calculator {
	my @queue = @_;
	my @stack;
	my ($first, $second);
	my $symbol;

	while ($symbol = shift @queue) {
		if ($symbol =~ m/\d/){		# NUMBER
			push @stack, $symbol;
		}
		else {						# OPERATOR
			$second = pop @stack;
			$first  = pop @stack;
			if    ($symbol eq "+") { push @stack, $first + $second }
			elsif ($symbol eq "-") { push @stack, $first - $second }
			elsif ($symbol eq "*") { push @stack, $first * $second }
			elsif ($symbol eq "/") { push @stack, $first / $second }
		}
	}
	return pop @stack;
}

sub recursive_descent {
}

my @infix = @tokens;
my @postfix = infix_to_postfix(@infix);
print @infix;
print @postfix;
print reverse_polish_calculator @postfix;



__END__

PEMDAS

P  Parentheses first
E  Exponents (ie Powers and Square Roots, etc.)
MD Multiplication and Division (left-to-right)
AS Addition and Subtraction (left-to-right)

Divide and Multiply rank equally (and go left to right).

Add and Subtract rank equally (and go left to right)


WIKIPEDIA https://en.wikipedia.org/wiki/Shunting-yard_algorithm


while there are tokens to be read:
    read a token.
    if the token is a number, then:
        push it to the output queue.
    else if the token is a function then:
        push it onto the operator stack 
    else if the token is an operator then:
        while ((there is an operator at the top of the operator stack)
              and ((the operator at the top of the operator stack has greater precedence)
                  or (the operator at the top of the operator stack has equal precedence and the token is left associative))
              and (the operator at the top of the operator stack is not a left parenthesis)):
            pop operators from the operator stack onto the output queue.
        push it onto the operator stack.
    else if the token is a left parenthesis (i.e. "("), then:
        push it onto the operator stack.
    else if the token is a right parenthesis (i.e. ")"), then:
        while the operator at the top of the operator stack is not a left parenthesis:
            pop the operator from the operator stack onto the output queue.
        /* If the stack runs out without finding a left parenthesis, then there are mismatched parentheses. */
        if there is a left parenthesis at the top of the operator stack, then:
            pop the operator from the operator stack and discard it
        if there is a function token at the top of the operator stack, then:
            pop the function from the operator stack onto the output queue.
/* After while loop, if operator stack not null, pop everything to output queue */
if there are no more tokens to read then:
    while there are still operator tokens on the stack:
        /* If the operator token on the top of the stack is a parenthesis, then there are mismatched parentheses. */
        pop the operator from the operator stack onto the output queue.
exit.


sub infix_to_postfix {
	my @stack;
	my @queue;
	my $token;
	my $op;
	my %precedence = ("(" => 2, ")" => 2, "*" => 1, "/" => 1, "+" => 0, "-" => 0);
	my %associativity = ("*" => "both?", "/" => "", "+" => "both?", "-" => "");

	foreach $token (@_){

		if ($token =~ /\d/) {				# NUMBER
			push @queue, $token;
		}

#		elsif ($token is a function) {		# FUNCTION
#			push @stack, $token;
#		}

		elsif ($token =~ m|[-+*/]|) {		# OPERATOR
#			while (($#stack >= 0)
#				  and (( $precedence{$token} < $precedence{$stack[$#stack]} )
#					  or (  $precedence{$token} == $precedence{$stack[$#stack]} and $associativity{$token} eq "left"  ))
#				  and ( $stack[$#stack] ne "("  )) {

			while (($#stack >= 0) 
				  and ( $precedence{$token} < $precedence{$stack[$#stack]} )
				  and ( $stack[$#stack] ne "(" ) ) {

				push @queue, pop @stack;
			}
			push @stack, $token;
		}

		elsif ( $token eq "(" ) {			# OPENING PARENTHESIS
			push @stack;
		}

		elsif ( $token eq ")" ) {			# CLOSING PARENTHESIS
			while ($stack[$#stack] ne "(") {
				push @queue, pop @stack;
			}
			/* If the stack runs out without finding a left parenthesis, then there are mismatched parentheses. */
			if ( $stack[$#stack] eq "(" ) {
				pop @stack;					# operator
			}
#			if ( $stack[$#] is a function ) {
#				push @queue, pop @stack;	# function
#			}
		}
	} # end foreach

	while ($op = pop @stack){
		push @queue, $op;
	}

	return @queue;

}
