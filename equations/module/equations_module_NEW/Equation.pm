
package Equation;
use strict;
use warnings;
use lib ".";
use Equation::Parser;
use Expression::Stringify;
use Operations;
# use Data::Dumper;
use finding_things;
use dd;

our %precedence;        *precedence        = *Operations::precedence{HASH};
our %left_associative;  *left_associative  = *Operations::left_associative{HASH};
our %right_associative; *right_associative = *Operations::right_associative{HASH};
our %inverse;           *inverse           = *Operations::inverse{HASH};


# remove trees and put left_side and right_side directly on the root

# CLASSES
# "path" --> array of nodes, for isolate ==?? applying inference rules to transform a proposition ??
# expression

# METHODS
# inverse_sides
# factorisation (NFA --> DFA ???)
# a - a
# a + a
# function/operation and its inverse
# forcer au carre

# suites / series

# domain / set ?

# logic ? proposition ? closure property ?


# can fusion variables ? (given a set of allowed rules)


# abstract machine ????






sub new {
    my $class = shift;
    my $equation = shift;
    my %self;
    $self{trees} = parse_equation($equation);

    bless \%self, $class;
}


# variable to isolate

# on right side of multiply -> divide other side of equation by left subtree
# on left  side of multiply -> divide other side of equation by right subtree
#     (variable do not change of side in either case)

# on right side of divide   -> multiply other side of eqution by right subtree (contains variable to isolate)
#                              (variable change of side)
# on left  side of divide  -> multiply other side of eqution by right subtree

# on right side of addition -> substract other side of eqution by left subtree
# on left  side of addition -> substract other side of eqution by right subtree
#     (variable do not change of side in either case)

# on right side of substraction -> addition other side of eqution by right subtree (contains variable to isolate)
#                                   (variable change of side)
# on left  side of substraction -> addition other side of eqution by right subtree

sub isolate {
    my $equation = shift;
	my %params = @_;
	my $variable;
	my $node;
	my @operations;
	my $operation;
	our $variable_op_side;
	our $equation_side;

	sub other_equation_side { $equation_side eq "left_side" ? "right_side" : "left_side" }
	sub other_variable_op_side { $variable_op_side eq "left" ? "right" : "left" }

# ./equations.pl 'y=3^x,x,y=1'
# ./equations.pl 'y=2^3^x,x,y=2'

# 	($equation_side, @operations) = find_node_path(%params);
# 	($equation_side, @operations) = find_node_path2($equation, $params{which}) if $params{node};
# 	($equation_side, @operations) = find_var_path2($equation, $params{which}) if $params{variable};
# 	($equation_side, @operations) = find_node_path2($equation, $params{which}) if exists $params{node};
# 	($equation_side, @operations) = find_var_path2($equation, $params{which}) if exists $params{variable};
    if (exists $params{variable}) {
	    ($equation_side, @operations) = find_var_path2($equation, $params{variable})
    }
    elsif (exists $params{node}) {
	    ($equation_side, @operations) = find_node_path2($equation, $params{node})
    }
#     print "-" x 40;
#     dd $equation_side;
#     dd \@operations;
#     print Dumper $equation_side;
#     print Dumper \@operations;

#     dd $equation;
#     dd $params{variable};
#     exit;

# 	foreach (grep {$_->{value} eq "^" and $_->{side} eq "right"  } @operations) {
# 		
# 		tree_substitute($equation->{trees}->{$equation_side},
# 						{ type => "binary_op", value => "^", capture => { 0 => "left", 1 => "right" } },
# 						{ type => "unary_op", value => "exp",
# 								operand =>{ type => "binary_op", value => "*",
# 									capture => { 1 => "left" },
# 									right => { type => "unary_op", value => "ln", capture => { 0 => "operand" } } }
# 						}
# 		)
# 	}
# 	tree_walk($equation->{trees}->{left_side}, sub { delete $_[0]->{id} });
# 	tree_walk($equation->{trees}->{right_side}, sub { delete $_[0]->{id} });
# 	mark_nodes($equation );
#     print "calling find_node_path()";
# 	($equation_side, @operations) = find_node_path(%params);
	$equation = $equation->{trees};

#     dd \@operations;
#     dd $operations[0];

	while (defined ($operation = shift @operations)) {
		$variable_op_side = $operation->{side} if exists $operation->{side};	# case of unary operators
#         dd $equation;
#         dd $operation;
#         print "="x40;
#         if (e)

		if ($operation->{type} eq "binary_op") {

			# ADDITION MUTIPLICATION
			if ($left_associative{$operation->{value}} and $right_associative{$operation->{value}}) {
#                 print "HERE";

				$equation->{other_equation_side()} =
                { type => "binary_op",
                 value => $inverse{ $operation->{value} },
                    id => $operation->{id},
                  left => $equation->{other_equation_side()},
                 right => $equation->{$equation_side}->{other_variable_op_side()}
                };

#                 dd $equation->{$equation_side}->{$variable_op_side};
				$equation->{$equation_side} = $equation->{$equation_side}->{$variable_op_side};
#                 print "\$equation_side\t\t$equation_side";
#                 print "\$variable_op_side\t\"$variable_op_side\"";
#                 dd $equation;
			}

			#  SUBSTRACTION DIVISION
			elsif ($left_associative{ $operation->{value} }) {

				$equation->{other_equation_side()} =
                { type => "binary_op",
                 value => $inverse{ $operation->{value} },
                    id => $operation->{id},
                  left => $equation->{other_equation_side()},
                 right => $equation->{$equation_side}->{right}
                };

				$equation->{$equation_side} = $equation->{$equation_side}->{left};

				if ($variable_op_side eq "right") {

					$equation_side = other_equation_side();

					unshift @operations,
                    { type => "binary_op",
                     value => $inverse{ $operation->{value} },
					  side => "right",
                        id => $operation->{id}
                    };
				}
			}
			#  POWER
			elsif ($right_associative{ $operation->{value} }) {

				if ($variable_op_side eq "left") {

					$equation->{other_equation_side()} =
                    { type => "binary_op",
                     value => $inverse{ $operation->{value} },
                        id => $operation->{id},
                     right => $equation->{$equation_side}->{right},
                      left => $equation->{other_equation_side()},
					};

					$equation->{$equation_side} = $equation->{$equation_side}->{left};
				}
				elsif ($variable_op_side eq "right") {
					die "reversing the power operator ^ to get the value of the right side shoudln't happen\n";
				}
			}
		}
        #  FUNCTIONS sqrt nth-root pow2 exp10 exp ln log log10 sin cos tan
		elsif ($operation->{type} eq "unary_op") {

				$equation->{other_equation_side()} =
                {   type => "unary_op",
                   value => $inverse{ $operation->{value} },
                      id => $operation->{id},
                 operand => $equation->{other_equation_side()}
                };

				$equation->{$equation_side} = $equation->{$equation_side}->{operand};
		}
	}
#     print "="x40;
#     print "END";
#     dd $equation;
#     exit;
	put_variable_on_the_left($equation);
}

sub substitute {	# substitute $inserted_equation INTO $master_equation
	my ($inserted_equation, $master_equation) = @_;
	# inserted_equation was previously isolated by the variable that is to be substituted into the master equation
	my $inserted_expression = $inserted_equation->{trees}->{right_side};
	my $insertion_point     = $inserted_equation->{trees}->{left_side}->{value};
	my $master_expression   = $master_equation->{trees}->{right_side};
# 	print $master_equation->{string};
	my @stack_tree_walk;
	my $node = $master_expression;
	push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0};

	while(@stack_tree_walk) {

		if ($node->{type} eq "variable" and $node->{value} eq $insertion_point) {	# variable to be substitued
			$node->%* = $inserted_expression->%*;
		}

		if ($node->{type} eq "binary_op") {
			if (not $stack_tree_walk[-1]->{left_visited}) {
				$node = $node->{left};
				$stack_tree_walk[-1]->{left_visited} = 1;
				push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0};
			}
			elsif (not $stack_tree_walk[-1]->{right_visited}) {
				$node = $node->{right};
				$stack_tree_walk[-1]->{right_visited} = 1;
				push @stack_tree_walk, {$node->%*, left_visited => 0, right_visited => 0};
			}
			else {
				pop @stack_tree_walk;
				if (@stack_tree_walk) {
					$node = $stack_tree_walk[-1];
				}
			}
		}
		elsif ($node->{type} eq "unary_op") {
			if (not $stack_tree_walk[-1]->{operand_visited}) {
				$node = $node->{operand};
				$stack_tree_walk[-1]->{operand_visited} = 1;
				push @stack_tree_walk, {$node->%*, operand_visited => 0};
			}
			else {
				pop @stack_tree_walk;
				if (@stack_tree_walk) {
					$node = $stack_tree_walk[-1];
				}
			}
		}
		else {
			pop @stack_tree_walk;
			$node = $stack_tree_walk[-1];
		}
	}
}



sub symbolic_derivative {
	my $tree = shift;
# 	print "symbolic_derivative";
	if ($tree->{type} eq "binary_op") {
		if ($tree->{value} eq "+") {
# 			print "PLUS";
			return {
                         type => "binary_op",
                        value => "+",
                         left => symbolic_derivative($tree->{left}),
                        right => symbolic_derivative($tree->{right}),
                   }
		}
		elsif ($tree->{value} eq "-") {
# 			print "MINUS";
			return {
                         type => "binary_op",
                        value => "-",
                         left => symbolic_derivative($tree->{left}),
                        right => symbolic_derivative($tree->{right}),
                   }
		}
		elsif ($tree->{value} eq "*") {
# 			print "TIMES";
			return {
                         type => "binary_op",
                        value => "+",
                         left => {
                                    type => "binary_op",
                                   value => "*",
                                    left => $tree->{left},
                                   right => symbolic_derivative($tree->{right}),
                                 },
                        right => {
                                    type => "binary_op",
                                   value => "*",
                                    left => $tree->{right},
                                   right => symbolic_derivative($tree->{left}),
                                },
                   }


		}
		elsif ($tree->{value} eq "/") {
# 			print "DIVIDE";
		}
		elsif ($tree->{value} eq "^") {		# case where power is a number
# 			print "POWER";
			
			return {
                         type => "binary_op",
                        value => "*",
                         left => $tree->{right},
                        right => {
                                    type => "binary_op",
                                   value => "^",
                                    left => $tree->{left},
#                                    right => {type=> "number", value => ($tree->{right}->{value} - 1) },
                                   right => {type=> "number", value => ($tree->{right}->{value} - 1) },
                                },
                   }
		}
	}
	elsif ($tree->{type} eq "variable") {
# 		print "VARIABLE";
		return { type => "number", value => 1 }
	}
	elsif ($tree->{type} eq "number") {
# 		print "NUMBER";
		return { type => "number", value => 0 }
	}
	else {
		print "NO MATCH";
		print Dumper $tree;
	}
}


# also modify isolate, potentially substitute and recursive solve
sub copy {              # deep copy of a data structure
	my $struct = shift;
	my $copy;

	# the "parent" part and the 2nd and 3rd arguments to recursive call is to be verified

	if (ref $struct eq "ARRAY") {
		foreach my $idx (keys $struct->@*) {
			$copy->[$idx] = copy($struct->[$idx]);
		}
	}
	elsif (ref $struct eq "HASH") {
		foreach my $key (grep {$_ ne "parent"} keys $struct->%*) {
			$copy->{$key} = copy($struct->{$key});
		}
	}
	elsif (ref $struct eq "Equation") {
        $copy = {};
        bless $copy, "Equation";
		foreach my $key (grep {$_ ne "parent"} keys $struct->%*) {
			$copy->{$key} = copy($struct->{$key});
		}
	}
	elsif (ref $struct eq "") {		# scalar value, not a reference
		$copy = $struct;
	}
	elsif (ref $struct eq "SCALAR") {
		$copy = copy($struct->$*);
	}
	elsif (ref $struct eq "REF") {
		$copy = copy($struct->$*);
	}
	return $copy;
}


sub print_equation_info {
	my $equation = shift;
	local $,=" ";
	local $\="\n";
	print "EQUATION\t",  $equation->{string};
	print "VARIABLES\t", sort $equation->{variables}->@*;
	print "WANTS\t\t",   sort $equation->{wants}->@*;
	print "KNOWNS\t\t",  sort $equation->{knowns}->@*;
	print "UNKNOWNS\t",  sort $equation->{unknowns}->@*;
	print "";
}


1;
__END__

