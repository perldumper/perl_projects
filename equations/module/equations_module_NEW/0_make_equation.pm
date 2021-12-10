
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

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

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

        if    ($_ eq "(") { $level++ }
        elsif ($_ eq ")") { $level-- }

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

