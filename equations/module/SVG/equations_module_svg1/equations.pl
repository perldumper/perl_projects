#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use lib "./";
use maths_operations;
use make_equation;
use equation_operations;
use finding_things;
use equation_output;
use graph;
use set_operations;
use graphviz;

#############################################################
# BUGS
# ./equations.pl 'y=x^(5+5),x,y=1'

# ./equations.pl 'c*(d-e)/((f-g)-a*b)=(z-x)*(y+u) , e, c=1,d=2,f=3,g=4,a=h-3*(i+k),h=5,i=6,k=7,b=8,z=4,x=2,y=2,u=2'

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

# identify part amoung find_node_path that are not bijective
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
my @equations_strings;
our @var_knowns;
our %var_knowns_values;
my @var_wants;

my $debug = 0;

if (@ARGV) {
	if ($ARGV[0] eq "debug") { shift; $debug = 1 }
	if (-e $ARGV[0]) { $input = <ARGV>  }
	else             { $input = $ARGV[0]}
}
elsif (not -t STDIN) { $input = <STDIN> }
else                 { exit }

my $level=0;
my $buf="";
my @assertions;

# make the tokenizer recognize commas for nth-root(27,3)

foreach (split //, $input) {
# 	print "$level $_";
	$level++ if $_ eq "(";
	$level-- if $_ eq ")";
	if ($level==0 and $_ eq ",") {
# 		print "here $_";
# 		print "buf $buf";
		push @assertions, $buf;
		$buf="";
	}
	else { $buf .= $_ }
}
# print "END buf $buf";
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
			|  ^ (?<value> [-+]? [0-9]+ \.? [0-9]* ) \s* = \s* (?<variable> [a-zA-Z][a-zA-Z0-9]* ) $ /x
		)   { push @var_knowns, $+{variable}; $var_knowns_values{$+{variable}} = $+{value} }

	elsif ($assertion =~ m/=/)
			{ push @equations_strings, $assertion }		# EQUATIONS
	else	{ push @var_wants, $assertion }		# WANTS
}

@var_knowns = sort @var_knowns;
@var_wants = sort @var_wants;

# print "EQUATIONS";
# print @equations;


########################
#     MAIN PROGRAM     #
########################

my @equations;
my $var;
my $master_equation;

foreach (@equations_strings) {
	push @equations, { trees => make_equation($_) };
	$equations[-1]->{string} = stringify($equations[-1]);
	push $equations[-1]->{steps}->@*, $equations[-1]->{string};
}

foreach my $eq (@equations) {
#  	#mark_nodes($eq);
	mark_nodes2($eq);
#  	#mark_nodes3($eq);
# 	make_graph($eq);
	$eq->{nodes}->%* = find_nodes($eq);
# 
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
# 	print Dumper $eq->{graph};
# 	print Dumper $eq;
}

# print Dumper $equations[1];

foreach (@equations) {
	$_->{variables}->@* = find_variables($_);
	$_->{knowns}->@* = set_intersection( $_->{variables}, \@var_knowns);
	$_->{wants}->@*  = set_intersection( $_->{variables}, \@var_wants);
	$_->{unknowns}->@* = set_difference( $_->{variables}, \@var_knowns);
# 	print_equation_info($_);
}

if (@var_wants == 0 ) {die "no variable that need to be determined was given"}
my ($wanted_var) = @var_wants;
my ($expanded_equation, $solution) = recursive_solve($wanted_var, @equations);
if ($expanded_equation == 0) { die "can not solve system of equations\n"}



# NOT CURRENTLY POSSIBLE BECAUSE OF EXP LOG LOG10 SIN COS TAN
# my $infix = tree_to_infix($expanded_equation->{trees}->{right_side});
# my $infix_result = eval($infix);

my @postfix = tree_to_postfix($expanded_equation->{trees}->{right_side});
my $postfix_result = reverse_polish_calculator(@postfix);

# if ($infix_result ne $postfix_result) {
# 	print "infix calculations and postfix calculations differ";
# 	print "infix  calculation ---> $wanted_var = $infix_result";
# 	print "postix calculation ---> $wanted_var = $postfix_result";
# }

# START CLEAN OUPUT
# print stringify($equations[-1]);
print $equations[-1]->{steps}->@*;
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

# __END__

# print Dumper $solution->{trees};
# tree_walk_sub($solution->{trees}->{left_side}, sub { delete $_[0]->%{"id","value"} });
# tree_walk_sub($solution->{trees}->{right_side}, sub { delete $_[0]->%{"id","value"} });
# tree_walk_sub($solution->{trees}->{left_side}, sub { delete $_[0]->%{key} });
# tree_walk_sub($solution->{trees}->{right_side}, sub { delete $_[0]->%{key} });
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



my $tree_pattern = { type => "binary_op", value => "-", capture => {0=>"right",1=>"left"}  };
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


__END__

./equations.pl 'a+b+c=d*e, c=f+g,d,g=78,a=1,b=1,e=1,f=1'
./equations.pl 'c*(d-e)/((f-g)-a*b)=(z-x)*(y+u) , e, c=1,d=2,f=3,g=4,a=h-3*(i+k),h=5,i=6,k=7,b=8,z=4,x=2,y=2,u=2'

