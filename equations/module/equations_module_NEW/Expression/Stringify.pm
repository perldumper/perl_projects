
package Expression::Stringify;
use strict;
use warnings;
use Exporter 'import';
use Operations;
use finding_things;

our %precedence;        *precedence        = *Operations::precedence{HASH};
our %left_associative;  *left_associative  = *Operations::left_associative{HASH};
our %right_associative; *right_associative = *Operations::right_associative{HASH};

our @EXPORT = qw(new_stringify old_stringify);
our @EXPORT_OK = qw(tree_to_postfix postfix_to_infix set_parent tree_to_infix);

#############################
# TO DO
# put all parentheses, put no required parentheses
# put some non required parenteses, around a quotient, or around an entire numerator / denominator
# when consecutive divides a/b/c --> (a/c)/c  and power a^b^c --> a^(b^c)

# recursive descent parser

##########################################################################
###########
#   NEW   #
###########

# sub set_parent; # --> use finding_things;

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
				die "node is neither the left nor right subtree of its parent, which is a binary_op\n";
			}
		}
		else {	# unary_op or top of the tree
			return 1
		}
	}
	else {	# top of the tree (or parent not added / updated by isolate or other function)
		return 1
	}
}

# make option to put parentheses around - and / even if it is not necessary 3-2-1 12/4/2
sub tree_to_infix {
	my $node = shift;
	my $infix = "";
	if ($node->{type} eq "binary_op") {
        # SPECIAL CASE
        # if (exists $special_cases{ $node->{value} } ) { $infix .= tree_to_infix_special_cases($node) }
		if ($node->{value} eq "nth-root") {
			if ($node->{right}->{type} eq "number" and $node->{right}->{value} == 2) { # sqrt(x)
				$infix .= "sqrt(";
				$infix .= tree_to_infix($node->{left});
				$infix .= ")";
			}
			else {																	   # nth-root(3,x)
				$infix .= tree_to_infix($node->{left});
				$infix .= "^(1/";
				$infix .= tree_to_infix($node->{right});
				$infix .= ")";
			}
		}
        # GENERAL CASE
		else {
			if (can_remove_outer_parens_operand($node)) {	# because precedence and assoc of outer operator relative to 
															# precedence and associativity of operator inside operand allows it
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


sub new_stringify {
	my $equation = shift;
	set_parent($equation->{trees}->{left_side});
	set_parent($equation->{trees}->{right_side});
	join "", tree_to_infix($equation->{trees}->{left_side}),
	" = ",
 	tree_to_infix($equation->{trees}->{right_side});
}


###########
#   OLD   #
###########

sub get_operand {
    my $stack = shift;
    my @operand;
    my $level;
    if ($stack->[-1] =~ m/\d|[a-zA-Z]/) {

        unshift @operand, pop $stack->@*;
        if ($stack->@*) {
            until ($stack->[-1] =~ m/\d|[a-zA-Z]/ or $stack->[-1] eq ")" ) {
                unshift @operand, pop $stack->@*;
            }
        }
    }
    elsif ($stack->[-1] eq ")" ) {
        $level = 1;
        while ($level > 0) {
            unshift @operand, pop $stack->@*;
            $level-- if $stack->[-1] eq "(" ;
            $level++ if $stack->[-1] eq ")" ;
        }
        unshift @operand, pop $stack->@*;
        if ($stack->@*) {
            if ($stack->[-1] =~ m/^(?:sqrt|exp|exp10|ln|log|log10|pow2|nth-root|arcsin|arccos|arctan|sin|cos|tan)$/) {
                unshift @operand, pop $stack->@*;
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

sub postfix_to_infix {
	our @queue = @_;
# 	our @stack = ();
	my $stack;
	my $token;
	my $level;
	my @right;
	my @left;
	my @operand;

	while ( defined ($token = shift @queue)) {

# 		print "TOKEN $token\n";

		if ($token =~ m#^(?:[-+/*%^]|nth-root)$#) {

# 			@right = get_operand();
# 			@left  = get_operand();
			@right = get_operand($stack);
			@left  = get_operand($stack);
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
					push $stack->@*, "sqrt", "(", @left, ")";				# sqrt(x)
				}
				else {
# 					push @stack, $token, "(", @right, ",", @left, ")";	# nth-root(3,x)
					push $stack->@*, "(",  @left, "^", "1", "/", @right, ")";			# x^3
				}
			}
			else {
				push $stack->@*, "(", @left, $token, @right, ")";
			}
		}
		elsif ($token =~ m/^(?:sqrt|exp|exp10|ln|log|log10|pow2|arcsin|arccos|arctan|sin|cos|tan)$/ ) {
# 			print "STACK @stack\n";
# 			@operand = get_operand();
			@operand = get_operand($stack);
# 			print "OPERAND @operand\n";
			push $stack->@*, $token, "(", @operand, ")";
# 			print "STACK @stack\n";
		}
		elsif ($token =~ m/\d|[a-zA-Z]/) {
			push $stack->@*, $token;
		}
	}

# 	print "STACK @stack\n";
	if ($stack->[0] eq "(") {
		return remove_outer_parens($stack->@*)
	}
	else {
		return $stack->@*;
	}
}


# post-order tree traversal, to obtain infix expression
sub tree_to_postfix {
	my $node = shift;
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


sub old_stringify {
	my $equation = shift;
	join "", postfix_to_infix( tree_to_postfix($equation->{trees}->{left_side}) ),
	" = ",
 	postfix_to_infix( tree_to_postfix($equation->{trees}->{right_side}) );
}



1;
__END__

