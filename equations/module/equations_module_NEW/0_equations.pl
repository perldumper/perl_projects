#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use lib "./";
use maths_operations;			# has to be first, or at least, before being imported by other modules
use equation_manipulations;
use make_equation;
use equation_output;
use finding_things;
use graph;
use set_operations;
use graphviz;

#############################################################
# TO DO

# if (@var_wants == 0 )
 	#and $equations[0]->{trees}->{left_side}->{type} ne "variable")
# 	{die "no variable that need to be determined was given"}
# PROBLEM
# $ ./equations.pl 'x=4+5'
# no variable that need to be determined was given at ./equations.pl line 1431.
# OTHER LIIMIT CASE   5+5 = 5+5 print true  or 5+5=5+6  print false
#   a+b = c + d, a=1, b=2, c=3, d=4  --> no wanted var given, but number of var_knowns == number of vars in the equation
#    --> shoud print false

# something like x = y = z but not x = y = z = 1 
# reversal of a^b operator problem --> convertto the form exp(b*ln(a)) unless b is a (positive?) integer --> nth-root / pow1_n

# if top node is a trig function --> give the result both in "decimal" and in radians --> something * pi

# identify part among find_node_path that are not bijective
#            ----> this variable can not be isolated / the eqation can not be solved ??


#############################################################

# Tie::IxHash ?? too heavy ??
#  to kind of conserve the same order in the binary expression tree, "arithmetic groups" inside parentheses, etc..

# associativity, precedence, reciproque/inverse operation, neutral element, inverse element ?
# distributivity, commutativity

#################################################################################


#######################
#    PARSING INPUT    #
#######################

$/=undef;
$\="\n";
my $input;
my $debug = 0;

if (@ARGV) {
	if ($ARGV[0] eq "debug") { shift; $debug = 1 }
	if (-e $ARGV[0]) { $input = <ARGV>  }
	else             { $input = $ARGV[0]}
}
elsif (not -t STDIN) { $input = <STDIN> }
else                 { exit }


########################
#     MAIN PROGRAM     #
########################

# exit;
my $sys = make_system($input);

my $func_name;
my $func_body;
my $deriv_level;


# if (@functions_strings == 1) {
# 	print "functions strings";
# 
# 
# 	if (@deriv_wants == 1) {
# 		if ($functions_strings[0] =~
# 				m| ^ [a-zA-Z][a-zA-Z0-9]* \s* \( \s* [a-zA-Z][a-zA-Z0-9]* (?: \s* , \s* [a-zA-Z][a-zA-Z]* )* \s* \) \s*
# 					  = \s* [a-zA-Z0-9\-+*/^()., ]+ $|x)
# 		{
# 			($func_name, $func_body) = split /=/, $functions_strings[0];
# 			print "FUNC NAME = FUNC BODY";
# 		}
# 
# 		elsif ($functions_strings[0] =~ m|^ \s* [a-zA-Z0-9\-+*/^()., ]+ \s* = 
# 					  \s* [a-zA-Z][a-zA-Z0-9]* \s* \( \s* [a-zA-Z][a-zA-Z0-9]* (?: \s* , \s* [a-zA-Z][a-zA-Z]* )* \s* \) \s* $|x)
# 		{
# 			($func_body, $func_name) = split /=/, $functions_strings[0];
# 			print "FUNC BODY = FUNC NAME";
# 		}
# 
# 		$deriv_level = () = $deriv_wants[0] =~ m/'/g;
# 		print "derivative level $deriv_level";
# 
# 	
# 		my @infix   = tokenize($func_body);
# 		@infix = simplify_signs(@infix);
# 		print "INFIX @infix";
# 		my @postfix = infix_to_postfix(@infix);
# 		print "POSTFIX @postfix";
# 		my $tree    = postfix_to_tree(@postfix);
# 		print Dumper $tree;
# 
# 		my $derivative = copy_data_structure($tree);
# 		print Dumper $derivative;
# 
# 		for (1 .. $deriv_level) {
# 			$derivative = symbolic_derivative($derivative);
# 
# 			simplify_term($derivative);
# 			$derivative = simplify_term($derivative);
# 		}
# 
# 		
# 		print $func_name =~ tr/ //dr, " = ", postfix_to_infix( tree_to_postfix($tree) );
# 		print $deriv_wants[0] =~ tr/ //dr, " = ", postfix_to_infix( tree_to_postfix($derivative) );
# 
# 		if (treewalk_lookfor_simplification($derivative)) {
# 			print "there is something to simplify";
# 		}
# 		else {
# 			print "there is nothing to simplify";
# 		}
# 
# 		print Dumper $derivative;
# 
# 	}
# 	else {
# 		die "function specified but no derivative wanted\n";
# 	}
# 
# 	exit;
# }
# 



if ($sys->{var_wants}->@* == 0 ) {die "no variable that need to be determined was given"}
my $wanted_var = $sys->{var_wants}[0];
my ($expanded_equation, $solution) = recursive_solve($wanted_var, $sys->{equations}->@*);
if ($expanded_equation == 0) { die "can not solve system of equations\n"}

print Dumper $wanted_var;
# print Dumper $expanded_equation;
print Dumper $solution;
exit;

# print Dumper $expanded_equation;

# NOT CURRENTLY POSSIBLE BECAUSE OF EXP LOG LOG10 SIN COS TAN
# my $infix = tree_to_infix($expanded_equation->{trees}->{right_side});
# my $infix_result = eval($infix);

my @postfix = tree_to_postfix($expanded_equation->{trees}->{right_side});
my $postfix_result = reverse_polish_calculator(@postfix);
# print @postfix;
# print $postfix_result;
exit;

# print "POSTFIX @postfix";

# if ($infix_result ne $postfix_result) {
# 	print "infix calculations and postfix calculations differ";
# 	print "infix  calculation ---> $wanted_var = $infix_result";
# 	print "postix calculation ---> $wanted_var = $postfix_result";
# }

# START CLEAN OUPUT
# print stringify($equations[-1]);
# print $equations[-1]->{steps}->@*;
print $sys->{equations}[0]{steps}->@*;
print_equation($solution);
print_equation($expanded_equation);
print "$wanted_var = $postfix_result";
# print "$wanted_var = $infix_result";
# END CLEAN OUPUT

# print Dumper $solution->{trees};
# print Dumper $expanded_equation->{trees};

# print @postfix;

# make_overall_graph(@equations);

$,="";

# my $pat = { type => "binary_op", capture => {0=>"type"}, value => "/", right => { capture => {1=>"type"},type => "number", value => 1 } };

# my ($res, @cap)=tree_starts_with2($expanded_equation->{trees}->{right_side}, $pat);
# if (tree_starts_with2($expanded_equation->{trees}->{right_side}, $pat)) {
# if ($res){
# 	print "TRUE";
# 	print "CAPTURE";
# 	print Dumper @cap;
# }
# else {
# 	print "FALSE";
# }

# equation_dumper($solution);
# equation_dumper($expanded_equation);



# __END__

# print Dumper $solution->{trees};
# tree_walk($solution->{trees}->{left_side}, sub { delete $_[0]->%{"id","value"} });
# tree_walk($solution->{trees}->{right_side}, sub { delete $_[0]->%{"id","value"} });
# tree_walk($solution->{trees}->{left_side}, sub { delete $_[0]->%{key} });
# tree_walk($solution->{trees}->{right_side}, sub { delete $_[0]->%{key} });
# print Dumper $solution->{trees};



# my $tree_pattern = { type => "binary_op", value => "+" };
# my $tree_pattern = { type => "binary_op", value => "-" };
# my $tree_pattern = { type => "binary_op", value => "-", capture => [0,"right"] , left => { type => "unary_op", value => "exp" } };
# my $tree_pattern = { type => "binary_op", value => "-", capture => {0=>"right",1=>"left"} , left => { type => "unary_op", value => "exp" } };
# my $tree_pattern = { type => "binary_op", value => "*" };
# my $tree_pattern = { type => "binary_op", value => "/", right=> {type=> "variable", value=> "e" } };
# my $tree_pattern = { type => "binary_op", value => "/", right=> {type=> "variable" } };

# my ($res,@cap) = tree_starts_with($solution->{trees}->{right_side}, $tree_pattern);
# if ($res) {
# 	print "true";
# 	if (@cap) {
# 		print "CAPTURE";
# 		print Dumper @cap;
# 		print Dumper $cap[0];
# 		print Dumper $cap[1];
# 	}
# 	else { print "NO CAPTURE" }
# }
# else { print "false" }

# my $tree_pattern = { type => "binary_op", value => "-", capture => {0=>"right",1=>"left"}  };

# if(tree_starts_with($solution->{trees}->{right_side}, $tree_pattern) ) {
# 	print "MATCH";
# 	print @cap;
# }
# else {
# 	print "NO MATCH";
# }
# 
# if (my @caps=tree_match($solution->{trees}->{right_side}, $tree_pattern)) {
# 	print "MATCH";
# 	print Dumper $_ foreach @caps;
# 	print @caps;
# 	print Dumper $solution->{trees};
# 	print Dumper $solution->{nodes}->{$_} foreach @caps;
# }
# else {
# 	print "NO MATCH";
# }



# my $tree_pattern = { type => "binary_op", value => "-", capture => {0=>"right",1=>"left"}  };
# my $tree_pattern = { type => "binary_op", value => "-", capture => {0=>"right",1=>"left"} , left => { type => "unary_op", value => "exp" } };

# print Dumper $solution->{trees}->{right_side};

# tree_substitute($solution->{trees}->{right_side},
#                 $tree_pattern,
#                { type => "unary_op", value => "ln", capture => { 0=> "operand" } }
#                { type => "binary_op", value => "+", capture => { 0=> "right", 1=>"left" } }
# );

# print Dumper $solution->{trees}->{right_side};


# print Dumper $equations[0]->{trees};

# tree_substitute($equations[0]->{trees}->{right_side},$tree_pattern);



# print Dumper $tree_pattern;



# print_equation($copy);


# print_graphviz make_graphviz_tree $equations[0];
# print_graphviz make_graphviz_tree $equations[1];
# print_graphviz_tmpfs make_graphviz_tree $solution;	# CURRENT
# find out why there is only a single arrow on the c node in :
# ./equations.pl 'a+b+c=d*e, c=f+g,d,g=78,a=1,b=1,e=1,f=1'


# __END__

# ./equations.pl 'a+b+c=d*e, c=f+g,d,g=78,a=1,b=1,e=1,f=1'
# ./equations.pl 'c*(d-e)/((f-g)-a*b)=(z-x)*(y+u) , e, c=1,d=2,f=3,g=4,a=h-3*(i+k),h=5,i=6,k=7,b=8,z=4,x=2,y=2,u=2'



# sub tree_walk_stack {
# 	my $ndoe = shift;
# 	my $sub = shift;
# 	my @stack = @_;
# 
# 	my ($res, @path) = $sub->($node);
# 
# 	if ($node->{type} eq "binary_op") {
# 		tree_walk_stack($node->{left}, $sub, @stack);
# 		tree_walk_stack($node->{right}, $sub, @stack);
# 	}
# 	elsif ($node->{type} eq "unary_op") {
# 		tree_walk_stack($node->{operand}, $id, @stack);
# 	}
# 
# }
# 
# 
# sub find_node_path4 {
# 
# }
# 
# 
# print "";
# print $equations[0]->{string};
# equation_dumper($equations[0]);
# print "=" x 40;
# 
# foreach my $node_id (sort keys $equations[0]->{nodes}->%*) {
# 
# 	my ($side, @path) = find_node_path3($equations[0], $node_id);
# 	print "NODE $node_id $equations[0]->{nodes}->{$node_id}->{value}";
# 	print "SIDE $side";
# 	print "PATH \"@path\"";
# 	print "-" x 10;
# 
# }
# 
# print "=" x 40;
# print "";
# print $equations[0]->{string};
# equation_dumper($equations[0]);
# 







