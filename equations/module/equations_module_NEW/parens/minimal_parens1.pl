#!/usr/bin/perl

# a OP ( b OP c )
# (a OP b) OP c
# a OP ( b OP c OP d )
# (a OP b OP c ) OP d

use strict;
use warnings;
use Data::Dumper;
# use bigrat;

my %precedence = (
	"^"   => 3,
	"*"   => 2,
	"/"   => 2,
	"+"   => 1,
	"-"   => 1,
	"("   => 0,
	")"   => 0,
);

my %left_associative = (
	"*"   => 1,
	"/"   => 1,
	"+"   => 1,
	"-"   => 1,
	"^"   => 0,
);

my %right_associative = (
	"*"   => 1,
	"/"   => 0,
	"+"   => 1,
	"-"   => 0,
	"^"   => 1,
);

sub can_remove_outer_parens_operand {
	my $node = shift;
	if (exists $node->{parent}) {
		if ($node->{parent}->{type} eq "binary_op") {
			if ($node->{parent}->{left} == $node) {	# node is the left operand
				if (  (not $left_associative{ $node->{parent}->{value} }
                        and $precedence{ $node->{value} } > $precedence{ $node->{parent}->{value} })
                   or ( $left_associative{ $node->{parent}->{value} }
                        and $precedence{ $node->{value} } >= $precedence{ $node->{parent}->{value} } ))
				{
					return 1
				}
				else {
					return 0
				}
			}
			elsif ($node->{parent}->{right} == $node) { # node is the right operand
				if (  (not $right_associative{ $node->{parent}->{value} }
                        and $precedence{ $node->{value} } > $precedence{ $node->{parent}->{value} })
                   or ( $right_associative{ $node->{parent}->{value} }
                        and $precedence{ $node->{value} } >= $precedence{ $node->{parent}->{value} } ))
				{
					return 1
				}
				else {
					return 0
				}
			}
			else {
				die "node is neither the left-subtree nor right-subtree of its parent, which is a binary_op\n";
			}
		}
		else {	# unary_op or top of the tree
			return 1
		}
	}
	else {	# top of the tree
		return 1
	}
}

# modified in-order tree walking
sub tree_to_infix {
	my $node = shift;
	my $infix = "";
	if ($node->{type} eq "binary_op") {
		if (can_remove_outer_parens_operand($node)) {
			$infix .= tree_to_infix($node->{left});
			$infix .= $node->{value};
			$infix .= tree_to_infix($node->{right});
		}
		else {
			$infix .= "(";
			$infix .= tree_to_infix($node->{left});
			$infix .= $node->{value};
			$infix .= tree_to_infix($node->{right});
			$infix .= ")";
		}
		return $infix;
	}
	elsif ($node->{type} eq "unary_op") {
		$infix .= $node->{value};
		$infix .= "(";
		$infix .= tree_to_infix($node->{operand});
		$infix .= ")";
		return $infix;
	}
	else {
		return $node->{value};
	}
}
sub set_parent {
	my $node = shift;
	my $parent = shift;

	if (defined $parent) {	# every node except top of the tree
		$node->{parent} = $parent;
	}

	if ($node->{type} eq "binary_op") {
		set_parent($node->{left}, $node);
		set_parent($node->{right}, $node);
	}
	elsif ($node->{type} eq "unary_op") {
		set_parent($node->{operand}, $node);
	}
}

# 'y=1-(4*x+5)*x*2+3-4'
my $expression_tree =
   {
      'type' => 'binary_op',
     'value' => '-',
     'right' => { 'type' => 'number', 'value' => '4' },
      'left' => {
          'type' => 'binary_op',
         'value' => '+',
         'right' => { 'value' => '3', 'type' => 'number' },
          'left' => {
               'type' => 'binary_op',
              'value' => '-',
               'left' => { 'value' => '1', 'type' => 'number' }, 
              'right' => {
                   'type' => 'binary_op',
                  'value' => '*',
                  'right' => { 'value' => '2', 'type' => 'number' },
                   'left' => {
                        'type' => 'binary_op',
                       'value' => '*',
                       'right' => { 'type' => 'variable', 'value' => 'x' },
                        'left' => {
                             'type' => 'binary_op',
                            'value' => '+',
                            'right' => { 'value' => '5', 'type' => 'number' },  
                             'left' => {
                                  'type' => 'binary_op', 
                                 'value' => '*',
                                  'left' => {  'type' => 'number', 'value' => '4' },
                                 'right' => { 'value' => 'x', 'type' => 'variable'}
                                },
                          }
                      }
                 },
            },
      },
};

$\="\n";

sub tokenize;
sub infix_to_postfix;
sub postfix_to_tree;
sub make_equation;

sub tree_to_postfix;
sub postfix_to_infix;

# set_parent($expression_tree);
# print tree_to_infix($expression_tree);

exit unless @ARGV;
my $string = $ARGV[0];
my @infix = tokenize($string);
my @postfix = infix_to_postfix(@infix);
my $tree = postfix_to_tree(@postfix);

print postfix_to_infix(tree_to_postfix($tree));

set_parent($tree);
print tree_to_infix($tree);


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


sub make_equation {
	my $equation_string = shift;
	my ($left_expression, $right_expression) = split /=/, $equation_string;

# 	print "=" x 40;
# 	print "$equation_string";
# 	print "=" x 40;

	my @left_infix   = tokenize($left_expression);
	@left_infix = simplify_signs(@left_infix);
# 	print "LEFT_INFIX \"@left_infix\"";
	my @left_postfix = infix_to_postfix(@left_infix);
	my $left_tree    = postfix_to_tree(@left_postfix);
# 	exit;

# 	print "left_infix";
# 	print @left_infix;
# 	print "left_postfix";
# 	print @left_postfix;
# 	print "left_tree";
# 	print Dumper $left_tree;

# 	print "-" x 40;

	my @right_infix   = tokenize($right_expression);
# 	print "right_infix";
# 	print @right_infix;
	@right_infix = simplify_signs(@right_infix);
	my @right_postfix = infix_to_postfix(@right_infix);
	my $right_tree    = postfix_to_tree(@right_postfix);

# 	print "right_infix";
# 	print @right_infix;
# 	print "right_postfix";
# 	print @right_postfix;
# 	print "right_tree";
# 	print Dumper $right_tree;

# 	print "=" x 40;


# 	print $equation_string;
# 	print "=" x 40;

# 	$,=" ";
# 	$"=" ";
# 	$\="\n";
# 	print "@left_infix = @right_infix";
# 	print "@left_postfix = @right_postfix";
# 

	print Dumper $right_tree;
	exit;


	return {left_side => $left_tree, right_side=> $right_tree};
}


# post-order tree traversal, to obtain infix expression
sub tree_to_postfix {
	my $node = shift;
# 	print "=" x 40;
# 	print Dumper $node;
# 	print "=" x 40;
	my @postfix;
	if ($node->{type} eq "binary_op") {
		push @postfix, tree_to_postfix($node->{left});
		push @postfix, tree_to_postfix($node->{right});
		push @postfix, $node->{value};
		return @postfix;
	}
	elsif ($node->{type} eq "unary_op") {
		push @postfix, tree_to_postfix($node->{operand});
		push @postfix, $node->{value};
		return @postfix;
	}
	else {
		return $node->{value};
	}
}


sub postfix_to_infix {
	our @queue = @_;
	our @stack = ();
	my $token;
	my $level;
	my @right;
	my @left;
	my @operand;

	sub get_operand {
		my @operand;
		my $level;
		if ($stack[-1] =~ m/\d|[a-zA-Z]/) {
			unshift @operand, pop @stack;
			if (@stack) {
				until ($stack[-1] =~ m/\d|[a-zA-Z]/ or $stack[-1] eq ")" ) {
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
			if (@stack) {
				if ($stack[-1] =~ m/^(?:sqrt|exp|exp10|ln|log|log10|pow2|nth-root|arcsin|arccos|arctan|sin|cos|tan)$/) {
					unshift @operand, pop @stack;
				}
			}
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
		
		my $EXT_OP_right_assoc = $right_associative{ $external_op };
		my $EXT_OP_preced      = $precedence{ $external_op };
		my $minimum_OP_preced_OPERAND;

		if (@right == 1) {												# number
			if ($right[0] =~ m/\d|[a-zA-Z]/) {
				return 0;	# bare number, no parentheses to remove
			}
		}
		elsif (@right == 3) {											# number OP number / ( number )
			if ($right[0] eq "(" and $right[1] =~ m/\d|[a-zA-Z]/ ) {	# ( number )
				return 1;
			}
			elsif ($right[0] =~ /\d|[a-zA-Z]/ and $right[1] =~ m|^[-+/*%^]$| ) {	# number OP number
				
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
		
		my $EXT_OP_left_assoc = $left_associative{ $external_op };
		my $EXT_OP_preced     = $precedence{ $external_op };
		my $minimum_OP_preced_OPERAND;

		if (@left == 1) {												# number
			if ($left[0] =~ m/\d|[a-zA-Z]/) {
				return 0;
			}
		}
		elsif (@left == 3) {											# number OP number / ( number )
			if ($left[0] eq "(" and $left[1] =~ m/\d|[a-zA-Z]/ ) {		# ( number )
				return 1;
			}
			elsif ($left[0] =~ /\d|[a-zA-Z]/ and $left[1] =~ m|^[-+/*%^]$| ) {	# number OP number
				
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

	while ( defined ($token = shift @queue)) {
# 		print "=" x 40,"\n";
# 		print "TOKEN $token\n";

		if ($token =~ m#^(?:[-+/*%^]|nth-root)$#) {

			@right = get_operand();
			@left  = get_operand();
# 			print "RIGHT @right\n";
# 			print "LEFT @left\n";

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

			if ($token eq "nth-root") {
				if (@right == 1 and $right[0] == 2) {
# 					push @stack, "sqrt", "(", @left, ")";				# sqrt(x)
					push @stack, "(", "sqrt", "(", @left, ")", ")";				# sqrt(x)
				}
				else {
# 					push @stack, $token, "(", @right, ",", @left, ")";	# nth-root(3,x)
					push @stack, "(",  @left, "^", "(", "1", "/", @right, ")", ")";			# x^3
				}
			}
			else {
				push @stack, "(", @left, $token, @right, ")";
			}
		}
		elsif ($token =~ m/^(?:sqrt|exp|exp10|ln|log|log10|pow2|arcsin|arccos|arctan|sin|cos|tan)$/ ) {
# 			print "STACK @stack\n";
			@operand = get_operand();
			if ($operand[0] eq "(") {
				@operand = remove_outer_parens(@operand);
			}

# 			print "OPERAND @operand\n";
# 			push @stack, $token, "(", @operand, ")";
			push @stack, "(", $token, "(", @operand, ")", ")";
# 			print "STACK @stack\n";
		}
		elsif ($token =~ m/\d|[a-zA-Z]/) {
			push @stack, $token;
		}
	}

# 	print "STACK @stack\n";
	if ($stack[0] eq "(") {
		return remove_outer_parens(@stack)
	}
	else {
		return @stack;
	}
}

