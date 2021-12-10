#!/usr/bin/perl

use strict;
use warnings;

package equation_operations;

use Exporter 'import';
our @EXPORT = qw(
		isolate
		substitute
		recursive_solve
);

use maths_operations;
use finding_things;
use graph;
use set_operations;
use equation_output;

our %precedence;
our %left_associative;
our %right_associative;
our %inverse;
our @var_knowns;
our %var_knowns_values;

# my ($pkg) = caller();
# *precedence        = *$pkg::precedence;
# *inverse           = \${$pkg}{inverse};

*precedence        = *main::precedence;
*left_associative  = *main::left_associative;
*right_associative = *main::right_associative;
*inverse           = *main::inverse;

*var_knowns        = *main::var_knowns;
*var_knowns_values = *main::var_knowns_values;


###########################
#   EQUATION OPERATIONS   #
###########################

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
	my %params = (variable=> 0, node=> 0);
	%params = @_;
	my $equation = $params{equation}->{trees};
	my $variable;
	my $node;
	my @operations;
	my $operation;
	our $variable_op_side;
	our $equation_side;

	if ($params{variable}) {
		$variable = $params{which};
		@operations = find_node_path(variable=> 1, which=> $variable, expression=> $equation->{left_side});
		$equation_side = "left_side";

		if ( not $operations[0]) {
			if($equation->{left_side}->{value} eq $variable) {
				return $equation;
			}
			else {
			# variable not found in equation's left side
				@operations = find_node_path(variable=> 1, which=> $variable, expression=> $equation->{right_side});
				$equation_side = "right_side";
			}
		}
		if ( not $operations[0]) {
			if($equation->{right_side}->{value} eq $variable) {
				return $equation;
			}
			else {
			# variable not found in equation's right side
				die "variable $variable to isolate not found in the equation $params{equation}->{string}\n";
			}
		}
	}
	elsif ($params{node}) {
		$node = $params{which};
		@operations = find_node_path(node=> 1, which=> $node, expression=> $equation->{left_side});
		$equation_side = "left_side";

		if ( not $operations[0]) {
			if($equation->{left_side}->{id} == $node) {
				return $equation;
			}
			else {
			# variable not found in equation's left side
				@operations = find_node_path(node=> 1, which=> $node, expression=> $equation->{right_side});
				$equation_side = "right_side";
			}
		}
		if ( not $operations[0]) {
			if($equation->{right_side}->{id} == $node) {
				return $equation;
			}
			else {
			# variable not found in equation's right side
				die "node $node to isolate not found in the equation $params{equation}->{string}\n";
			}
		}
	}


	sub other_equation_side { return "right_side" if $equation_side eq "left_side"; return "left_side" }
	sub other_variable_op_side { return "right" if $variable_op_side eq "left"; return "left" }

	while (defined ($operation = shift @operations)) {
		$variable_op_side = $operation->{side} if exists $operation->{side};	# case of unary operators

		if ($operation->{type} eq "binary_op") {

			if ($left_associative{$operation->{value}} and $right_associative{$operation->{value}}) {	# ADDITION MUTIPLICATION

				$equation->{other_equation_side()} = { type=> "binary_op", value=> $inverse{ $operation->{value} },
															 id=> $operation->{id},
														   left=> $equation->{other_equation_side()},
														  right=> $equation->{$equation_side}->{other_variable_op_side()} };
				$equation->{$equation_side} = $equation->{$equation_side}->{$variable_op_side};
			}

			elsif ($left_associative{ $operation->{value} }) {	#  SUBSTRACTION DIVISION
				$equation->{other_equation_side()} = { type=> "binary_op", value=> $inverse{ $operation->{value} },
															 id=> $operation->{id},
														   left=> $equation->{other_equation_side()},
														  right=> $equation->{$equation_side}->{right} };
				$equation->{$equation_side} = $equation->{$equation_side}->{left};
				if ($variable_op_side eq "right") {
					$equation_side = other_equation_side();
					unshift @operations, {type=> "binary_op", value=> $inverse{ $operation->{value} },
												side=> "right", id=> $operation->{id} };
				}
			}
			elsif ($right_associative{ $operation->{value} }) {	#  POWER (verify this one)
				if ($variable_op_side eq "left") {
# 					print "RIGHT";
					$equation->{other_equation_side()} = { type=> "binary_op", value=> $inverse{ $operation->{value} },
																 id=> $operation->{id},
															  right=> $equation->{$equation_side}->{right},
															   left=> $equation->{other_equation_side()},
																										 };
					$equation->{$equation_side} = $equation->{$equation_side}->{right};
				}
				elsif ($variable_op_side eq "right") {
# 					$equation->{other_equation_side()} = { type=> "binary_op", value=> $inverse{ $operation->{value} },
# 																 id=> $operation->{id},
# 															  right=> $equation->{$equation_side}->{left},
# 															   left=> $equation->{other_equation_side()},
# 	 														   left=> $equation->{$equation_side}->{left},
# 	 														  right=> $equation->{other_equation_side()},
# 																										 };
# 					$equation->{$equation_side} = $equation->{$equation_side}->{right};
# 					$equation_side = other_equation_side();
# 					unshift @operations, {type=> "binary_op", value=> $inverse{ $operation->{value} },
# 												side=> "left", id=> $operation->{id} };
				}
			}
		}
		elsif ($operation->{type} eq "unary_op") {	#  FUNCTIONS sqrt nth-root pow2 exp10 exp ln log log10 sin cos tan
				$equation->{other_equation_side()} = { type=> "unary_op", value=> $inverse{ $operation->{value} },
														     id=> $operation->{id},
													    operand=> $equation->{other_equation_side()} };
				$equation->{$equation_side} = $equation->{$equation_side}->{operand};
		}
	}

	# put isolated variable on left
	my $temp_expression_storage;
	if ($equation->{right_side}->{type} eq "variable"
	 or $equation->{right_side}->{type} eq "number") {

		$temp_expression_storage = $equation->{right_side};
		$equation->{right_side} = $equation->{left_side};
		$equation->{left_side} = $temp_expression_storage;
	}
	elsif ($equation->{left_side}->{type} eq "variable"
	    or $equation->{left_side}->{type} eq "number") {
		return;
	}
	else {
		local $\="\n";;
		print_equation($params{equation});
		print "isn't in a form where one variable is alone on of the side of =";
		exit;
	}
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

sub recursive_solve {
	my ($wanted_var, @bag_of_equations) = @_;
	my @reduced_bag_of_equations;
	my $expanded_equation;
	my $temp_expanded_equation;
	my $solution;			# keep final expression, with all unknown variables substitued. varialbes not replaced by numbers
	my $temp_solution;
	my @in_function_of_vars;
	my @known_variables;
	my $var;
	my $variable_value;
	my $eq;

	unless (@bag_of_equations) {return 0}

	sub remove_equation {	# eliminate equations already substituted once to avoid "loops"
		my ($equation, @equation_set) = @_;
		for (my $i = 0; $i < @equation_set; $i++) {
			if ($equation_set[$i]->{string} eq $equation->{string}) {
				splice @equation_set, $i, 1;

			}
		}
		return @equation_set;
	}

	EQUATION:
	foreach my $eq (find_equations_containing_var($wanted_var, @bag_of_equations)) {
		@reduced_bag_of_equations = remove_equation($eq, @bag_of_equations);
		# what if variable appears multiple times ??

# 		isolate(variable=> 1, which=> $wanted_var, equation=> $eq);
# 		$expanded_equation = $eq;
# 		$solution = copy_data_structure($eq);

		$expanded_equation = copy_data_structure($eq);
		isolate(variable=> 1, which=> $wanted_var, equation=> $expanded_equation);
		$solution = copy_data_structure($expanded_equation);

		# what if variable appears multiple times ??
		@in_function_of_vars = set_difference([$eq->{variables}->@*], [$wanted_var]);

		if (set_inclusion(\@in_function_of_vars, \@var_knowns )) {
			foreach $var (@in_function_of_vars) {
				$variable_value = {trees=>
                                  {left_side=> {type=> "variable", value=> $var },
								  right_side=> {type=> "number",   value=> $var_knowns_values{$var} } }};
				substitute($variable_value, $expanded_equation);
			}
			return ($expanded_equation, $solution);			# recursive substitution successful
		}
		else {
			# what if variable appears multiple times ??
			@known_variables = set_difference(\$eq->{variables}->@*, \$eq->{unknowns}->@*);
			@known_variables = set_difference(\@known_variables, [$wanted_var]);			# just in case
			foreach $var (@known_variables) {
				$variable_value = {trees=>
                                  {left_side=> {type=> "variable", value=> $var },
								  right_side=> {type=> "number",   value=> $var_knowns_values{$var} } }};
				substitute($variable_value, $expanded_equation);
			}


			foreach $var (set_difference([$eq->{unknowns}->@*], [$wanted_var])) {
	
				($temp_expanded_equation, $temp_solution) = recursive_solve($var, @reduced_bag_of_equations);
				if ($temp_expanded_equation == 0) {next EQUATION}
				substitute($temp_expanded_equation,  $expanded_equation);
				substitute($temp_solution,  $solution);
			}
			return ($expanded_equation, $solution);			# recursive substitution successful
		}
	}
	return 0;							# recursive substitution unsuccessful, every starting points tried
}


1;
