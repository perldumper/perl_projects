
package System;
use strict;
use warnings;
use Equation;

sub new {
    my $class = shift;
    my %params = @_;
    my %self;
    foreach my $equation ($params{equations}->@*) {
        push $self{equations}->@*, Equation->new($equation)
    }
    if (exists $self{knowns}) {
        $self{knowns}->%* = $params{knowns}->%*;
    }
    bless \%self, $class;
}

my @var_knowns;
my %var_knowns_values;


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

		$expanded_equation = copy_data_structure($eq);
		isolate(variable=> 1, which=> $wanted_var, equation=> $expanded_equation);
		$solution = copy_data_structure($expanded_equation);

		# what if variable appears multiple times ??
		@in_function_of_vars = set_difference([$eq->{variables}->@*], [$wanted_var]);

		# if all the variables in this equation are known (besides $wanted_var)
		if (set_inclusion(\@in_function_of_vars, \@var_knowns )) {
			foreach $var (@in_function_of_vars) {	# substitute each known variable by its value
				$variable_value = {trees=>
                                  {left_side=> {type=> "variable", value=> $var },
								  right_side=> {type=> "number",   value=> $var_knowns_values{$var} } }};
				substitute($variable_value, $expanded_equation);
			}
			return ($expanded_equation, $solution);			# recursive substitution of all unknown variables is successful
		}
		# at least one variable in this equation is unknown (besides $wanted_var)
		else {
			# what if variable appears multiple times ??
			@known_variables = set_difference(\$eq->{variables}->@*, \$eq->{unknowns}->@*);
			@known_variables = set_difference(\@known_variables, [$wanted_var]);			# just in case
			foreach $var (@known_variables) {		# substitute each known variable by its value
				$variable_value = {trees=>
                                  {left_side=> {type=> "variable", value=> $var },
								  right_side=> {type=> "number",   value=> $var_knowns_values{$var} } }};
				substitute($variable_value, $expanded_equation);
			}

			# try substituting unknown variables by other equations containing it, which have been isolated by it
			foreach $var (set_difference([$eq->{unknowns}->@*], [$wanted_var])) {
	
				($temp_expanded_equation, $temp_solution) = recursive_solve($var, @reduced_bag_of_equations);
				if ($temp_expanded_equation == 0) {next EQUATION}
				substitute($temp_expanded_equation,  $expanded_equation);
				substitute($temp_solution,  $solution);
			}
			return ($expanded_equation, $solution);			# recursive substitution of all unknown variables is successful
		}
	}
	return 0;							# recursive substitution unsuccessful, every starting points tried
}


1;
__END__

