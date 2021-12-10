#!/usr/bin/perl

use strict;
use warnings;

$/=undef;
my $expression;

if (@ARGV) {
	if (-e $ARGV[0]) { $expression = <ARGV>  }
	else             { $expression = $ARGV[0]}
# 	else             { $expression = join " ", @ARGV }
}
elsif (not -t STDIN) { $expression = <STDIN> }
else                 { exit }

$,="";
$\="\n";

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
		elsif($expression =~ m/\G\^/gc)                    { push @tokens, "^" }
		elsif($expression =~ m/\G\%/gc)                    { push @tokens, "%" }

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
# 	my @tokens = @_;
# 	my @stack;
# 	my @queue;
	our @tokens = @_;
	our @stack;
	our @queue;
	my $token;
	my $op;
	my %precedence = ("(" => 2, ")" => 2, "*" => 1, "/" => 1, "+" => 0, "-" => 0);
# 	my %associativity = ("*" => "left", "/" => "left", "+" => "left", "-" => "left", "^" => "right", "%" => "right");
	my %associativity = ("*" => "left", "/" => "left", "+" => "left", "-" => "left", "^" => "right", "%" => "left");

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
					  or (  $precedence{$token} == $precedence{$stack[-1]} and $associativity{$token} eq "left"  ))
				  and ( $stack[-1] ne "("  )) {
# 			while (($#stack >= 0) 
# 				  and ( $precedence{$token} < $precedence{$stack[-1]} )
# 				  and ( $stack[-1] ne "(" ) ) {

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

	my %precedence = ("(" => 2, ")" => 2, "*" => 1, "/" => 1, "+" => 0, "-" => 0);
# 	my %associativity = ("*" => "left", "/" => "left", "+" => "left", "-" => "left", "^" => "right", "%" => "right");
	my %associativity = ("*" => "left", "/" => "left", "+" => "left", "-" => "left", "^" => "right", "%" => "left");

	$,=" ";
	$"=" ";
	$\="\n";

	sub get_operand {
		my @operand = ();
		my $level;
# 		print "QUEUE  @queue\nSTACK  @stack";
		if ($stack[-1] =~ m/\d/) {

			push @operand, pop @stack;
			if (@stack) {
				until ($stack[-1] =~ m/\d/ or $stack[-1] eq ")" ) {
					push @operand, pop @stack;
					print "QUEUE  @queue\nSTACK  @stack";
				}
			}

# 			print "QUEUE  @queue\nSTACK  @stack";
		}
		elsif ($stack[-1] eq ")" ) {
			$level = 1;
			while ($level > 0) {
# 				print "TOP OF STACK = $stack[-1]";
				unshift @operand, pop @stack;
# 				print "LEVEL = $level";
				$level-- if $stack[-1] eq "(" ;
				$level++ if $stack[-1] eq ")" ;
# 				print "QUEUE  @queue\nSTACK  @stack";
			}
			unshift @operand, pop @stack;
		}
# 		print "QUEUE  @queue\nSTACK  @stack";
		return @operand;
	}

	sub operand_info {
		my @operand = @_;
		my ($precedence, $associativity);
		my $level;
		my $i;
		if ($operand[0] =~ m/\d/) {
			return ( $precedence{ $operand[1] }, $associativity{ $operand[1] } )
				if $operand[1] =~ m|^[-+/*%^]$|;
		}
		elsif ($operand[0] eq "(" ) {
			$level = 1;
			for ($i=1; $i < @operand; $i++) {
				last if $level == 1 and $operand[$i] =~ m/^[-+/*%^]$/;	# find right most operator that would be on same level
				$level++ if $operand[$i] eq "(" ;					# than token operator if we remove paren aroud right operand
				$level-- if $operand[$i] eq ")" ;
			}
		}
	}


# 	print "QUEUE  @queue\nSTACK  @stack";

	while ($token = shift @queue) {

# 		print "TOKEN = $token";		
# 		print "QUEUE  @queue\nSTACK  @stack";

		if ($token =~ m|^[-+/*%^]$|) {

			@right = ();
			@right = get_operand();
# 			($precedence, $associativity) = operand_info(@right);

# 			print "QUEUE  @queue\nSTACK  @stack";
# 			print "RIGHT  @right";

			@left = ();
			@left  = get_operand();
# 			($precedence, $associativity) = operand_info(@left);

# 			print "QUEUE  @queue\nSTACK  @stack";
# 			print "QUEUE  @queue\nSTACK  @stack";
# 			print "LEFT  @left";

			push @stack, "(", @left, $token, @right, ")";
# 			print "QUEUE  @queue\nSTACK  @stack";
		}
		elsif ($token =~ m/\d/) {
			push @stack, $token;
# 			print "QUEUE  @queue\nSTACK  @stack";
		}
	}

# 	print "QUEUE  @queue\nSTACK  @stack";
	return @stack;	
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


# print reverse_polish_calculator(@postfix);
# print reverse_polish_calculator(reverse @postfix);




__END__


- the order of the numbers isn't changed between infix to postfix











