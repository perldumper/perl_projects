
package make_equation;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
		tokenize
		infix_to_postfix
		postfix_to_tree
		make_equation
        make_system
		simplify_signs
);

use maths_operations;
use equation_output;
use finding_things;
use set_operations;
use maths_operations;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

# our %precedence;       *precedence        = *main::precedence{HASH};
# our %left_associative; *left_associative  = *main::left_associative{HASH};
our %precedence;       *precedence        = *maths_operations::precedence{HASH};
our %left_associative; *left_associative  = *maths_operations::left_associative{HASH};


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


# reduce 5--5 into 5+5, 5+-+5 into 5-5, 5---5 into 5, etc..
sub simplify_signs {
	my @tokens = @_;

	for (my $i=0; $i < $#tokens; $i++) {	# avoid testing for definedness, expressions shouldn't finish by + or -

		if ($tokens[$i] eq "+") {
			if ($tokens[$i+1] eq "+" or $tokens[$i+1] eq "-") {
				splice @tokens, $i, 1;
				redo;
			}
		}
		elsif ($tokens[$i] eq "-") {
			if ($tokens[$i+1] eq "+") {
				splice @tokens, $i+1, 1;
				redo;
			}
			elsif ($tokens[$i+1] eq "-") {
				$tokens[$i] = "+";
				splice @tokens, $i+1, 1;
				redo;
			}
		}
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




# sub make_equation {
# 	my $equation_string = shift;
# 	my ($left_expression, $right_expression) = split /=/, $equation_string;
# 
# 	my @left_infix   = tokenize($left_expression);
# 	my @left_postfix = infix_to_postfix(@left_infix);
# 	my $left_tree    = postfix_to_tree(@left_postfix);
# 
# 	my @right_infix   = tokenize($right_expression);
# 	my @right_postfix = infix_to_postfix(@right_infix);
# 	my $right_tree    = postfix_to_tree(@right_postfix);
# 
# 	return {left_side => $left_tree, right_side=> $right_tree};
# }

sub make_equation {
	my $equation_string = shift;
	my ($left_expression, $right_expression) = split /=/, $equation_string;

# 	print "=" x 40;
# 	print "$equation_string";
# 	print "=" x 40;

	my @left_infix   = tokenize($left_expression);
	@left_infix = simplify_signs(@left_infix);
# 	print "LEFT_INFIX \"@left_infix\"";
	my @left_postfix = infix_to_postfix(@left_infix);   # shunting-yard
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

# 	print Dumper $right_tree;
# 	exit;


	return {left_side => $left_tree, right_side=> $right_tree};
}

sub make_system {
    my $input = shift;
    my $sys;

    my @functions_strings;
    my @equations_strings;
#     our @var_knowns;
    our %var_knowns_values;
#     my @var_wants;
    my @deriv_wants;
    
    my $level=0;
    my $buf="";
    my @assertions;

    # make the tokenizer recognize commas for nth-root(27,3)
    foreach (split //, $input) {
        $level++ if $_ eq "(";
        $level-- if $_ eq ")";
        if ($level==0 and $_ eq ",") {
            push @assertions, $buf;
            $buf="";
        }
        else { $buf .= $_ }
    }
    push @assertions, $buf if length $buf > 0;

    # my @assertions = split /,/, $input;
    # perl -le '$,="\n"; @array=split m/, (?= (?: ([^,]*? \( (?: [^()]++ | (?1))* \) ) ) )? /x, "a=1,b=1,c=nth-root(3,27), d=1"; $i=0; for(@array){print $i++; print}'

    # split this input string "a=1,b=1,c=nth-root(3,27), d=1"  --> it shouldn't split on the comma of "nth-root(3,27)"
    # workaround -> use nth-root as an infix operator

    # tr/ //d isn't good because we need to differentite log10 (decimal logarithm) from log 10 (natural logarithm of 10)
    s/^ +//g foreach @assertions;
    s/ +$//g foreach @assertions;

    while (defined (my $assertion = shift @assertions)) {

        if ($assertion =~							# KNOWNS
                m/ ^ (?<variable> [a-zA-Z][a-zA-Z0-9]* ) \s* = \s* (?<value> [-+]? [0-9]+ \.? [0-9]* ) $
                |  ^ (?<value> [-+]? [0-9]+ \.? [0-9]* ) \s* = \s* (?<variable> [a-zA-Z][a-zA-Z0-9]* ) $ /x)
        {
            push $sys->{var_knowns}->@*, $+{variable};
            $var_knowns_values{$+{variable}} = $+{value};
    # 		print "variable known";
        }

        elsif ($assertion =~							# FUNCTIONS
                m# ^ [a-zA-Z][a-zA-Z0-9]* \s* '* \s* \( \s* [a-zA-Z][a-zA-Z0-9]*
                           (?: \s* , \s* [a-zA-Z][a-zA-Z]* )* \s* \) \s*
                      = \s* [a-zA-Z0-9\-+*/^()., ]+ $
                   | ^ \s* [a-zA-Z0-9\-+*/^()., ]+ \s* = 
                   \s* [a-zA-Z][a-zA-Z0-9]* \s* '* \s* \( \s* [a-zA-Z][a-zA-Z0-9]*
                          (?: \s* , \s* [a-zA-Z][a-zA-Z]* )* \s* \) \s* $#x)
        {
            push $sys->{functions_strings}->@*, $assertion;
    # 		print "function string";
        }

        elsif ($assertion =~ m/=/)		# EQUATIONS
        {
            push $sys->{strings}->@*, $assertion;
    # 		print "equation \"$assertion\"";
        }

        elsif ($assertion =~ m/^[a-zA-Z][a-zA-Z0-9]*$/)		# VARIABLES WANTED
        {
            push $sys->{var_wants}->@*, $assertion;
    # 		print "variable wanted";
        }

        elsif ($assertion =~ m/^[a-zA-Z][a-zA-Z0-9]* \s* '* \s* \( \s* [a-zA-Z][a-zA-Z0-9]* (?:,\s* [a-zA-Z][a-zA-Z]* )* \s* \)$/x)
        {
            push $sys->{deriv_wants}->@*, $assertion;
    # 		print "deriv wanted";
        }	# FUNCTION WANTED (derivative)
    }

    $sys->{var_knowns}->@* = sort $sys->{var_knowns}->@*;
    $sys->{var_wants}->@* = sort $sys->{var_wants}->@*;

    my $var;
    my $master_equation;

    foreach ($sys->{strings}->@*) {
    # 	print Dumper $_;
        push $sys->{equations}->@*, { trees => make_equation($_) };
    # 	last;
        $sys->{equations}[-1]{string}->@* = stringify($sys->{equations}[-1]);
        push $sys->{equations}->[-1]{steps}->@*, $sys->{equations}[-1]{string};
    # 	print Dumper $equations[-1]->{trees};
    }

foreach my $eq ($sys->{equations}->@*) {

	mark_nodes($eq);
	$eq->{nodes}->%* = find_nodes($eq);
 
#  	#print_graphviz_tmpfs make_graphviz_tree $eq;
# 
# 	# foreach node that is a variable (necessary in case a variable appears more than once)
# 
# 	foreach my $node_id (	grep {$eq->{nodes}->{$_}->{type} =~ m/variable|number/} # include variables and numbers
# 							keys $eq->{nodes}->%* )
# 	{
# 		#print "NODE";
# 		#print $eq->{nodes}->{$node_id}->%*;
# 		isolate(node=> 1, which=> $node_id, equation=> $eq);
# 		make_graph($eq);
# 		#print_graphviz_tmpfs make_graphviz_tree $eq;
# 	}

}

    foreach ($sys->{equations}->@*) {
        $_->{variables}->@* = find_variables($_);
        $_->{knowns}->@*    = set_intersection( $_->{variables}, $sys->{var_knowns});
        $_->{wants}->@*     = set_intersection( $_->{variables}, $sys->{var_wants});
        $_->{unknowns}->@*  = set_difference(   $_->{variables}, $sys->{var_knowns});
    # 	print_equation_info($_);
#         print Dumper $_;
    }

#     exit;

    return $sys;
}
1;

