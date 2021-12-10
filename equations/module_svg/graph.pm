
package graph;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw(
		make_graph
		make_overall_graph
		equation_dumper
);


use finding_things;
# our @EXPORT_OK = qw(mark_nodes4);
# our @ISA = qw(finding_things);

use List::Util qw(any);
use Data::Dumper;
# use File::Temp q(tempfile);
# use Time::HiRes q(usleep);

#################
#     GRAPH     #
#################

sub make_graph {
	# visit all the nodes
	my $equation = shift;
	my $left_expression  = $equation->{trees}->{left_side};
	my $right_expression = $equation->{trees}->{right_side};
	my @stack_tree_walk;
	my $node;

	push $equation->{graph}->{$left_expression->{id}}->@*,
			$right_expression->{id}
# 		unless grep {/$right_expression->{id}/}
		unless any {/$right_expression->{id}/}
			$equation->{graph}->{$left_expression->{id}}->@*;

	push $equation->{graph}->{$right_expression->{id}}->@*,
			$left_expression->{id}
# 		unless grep {/$left_expression->{id}/}
		unless any {/$left_expression->{id}/}
			$equation->{graph}->{$right_expression->{id}}->@*;
	
	foreach my $expression ($left_expression, $right_expression) {
		@stack_tree_walk = ();
		$node = $expression;
		push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
		while(@stack_tree_walk) {

			if (@stack_tree_walk >= 2) {
				push $equation->{graph}->{$stack_tree_walk[-2]->{id}}->@*,
						$stack_tree_walk[-1]->{id}
# 					unless grep {/$stack_tree_walk[-1]->{id}/}
					unless any {/$stack_tree_walk[-1]->{id}/}
						$equation->{graph}->{$stack_tree_walk[-2]->{id}}->@*;
			}

			if ($node->{type} eq "binary_op") {			# interior node
				
				if (not $stack_tree_walk[-1]->{left_visited}) {
					$node = $node->{left};
					$stack_tree_walk[-1]->{left_visited} = 1;
					push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
				}
				elsif ($node->{side} eq "left") {
					$node = $node->{right};
					$stack_tree_walk[-1]->{side} = "right";
					push @stack_tree_walk, {$node->%*, left_visited => 0, side=> "left"};
				}
				else {
					pop @stack_tree_walk;
					$node = $stack_tree_walk[-1];
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
			else {										# leaf
				pop @stack_tree_walk;
				if (@stack_tree_walk) {
					$node = $stack_tree_walk[-1];
				}
			}
		}
	}
}

sub make_overall_graph {
	my @set_of_equations = @_;
	my $id = 0;
	my ($eq, $searched_eq, $var);
	foreach $eq (@set_of_equations) {
		$eq->{id} = $id;
		$id++;
	}
	my %equations_relations_graph;	# graph

	# create of graph of relations between equations
	foreach $eq (@set_of_equations) {
		SEARCHED_EQUATION:
		foreach $searched_eq ( grep { $_->{string} ne $eq->{string} }  @set_of_equations) {

			foreach $var ($eq->{variables}->@*) {
# 				if (grep {/$var/} $searched_eq->{variables}->@*) {
				if (any {/$var/} $searched_eq->{variables}->@*) {
					push $equations_relations_graph{$eq->{id}}->@*,          $searched_eq->{id};
					push $equations_relations_graph{$searched_eq->{id}}->@*, $eq->{id};

# 					push $equations_relations_graph{$eq->{string}}->@*,          $searched_eq->{string};
# 					push $equations_relations_graph{$searched_eq->{string}}->@*, $eq->{string};
					next SEARCHED_EQUATION;
				}
			}
		}
	}

	$eq = shift @set_of_equations;
	$eq = copy_data_structure($eq);


	while (defined ($eq = shift @set_of_equations)) {
		$eq = copy_data_structure($eq);
	}



# 	print Dumper \%equations_relations_graph;

	

}


sub equation_dumper {
	my $eq = shift;
	local $\="";

	sub tree_dumper {
		my $node = shift;
		my $level = shift;
		my @lines = @_;
		my $lines = " " x (3*$level);
		my $line;

		if ($level == 0) {
# 			print "------", "($node->{value})\n";
			print "------", "($node->{value}) $node->{id}\n";
		}
		elsif (exists $node->{parent} and $node->{parent}->{type} eq "binary_op") {

			substr $lines, 3*($_+1), 1, "  |" foreach @lines;
# 			$line = "   " x ($level) . "   " . "---" . "($node->{value})\n";
			$line = "   " x ($level) . "   " . "---" . "($node->{value}) $node->{id}\n";
			$line = $line | $lines;

			if ($node->{parent}->{left} == $node ) {
				substr $line, (3*$level+2), 1, "L";
				print $line;
			}
			elsif ($node->{parent}->{right} == $node) {
				substr $line, (3*$level+2), 1, "R";
				print $line;
			}
		}
		elsif (exists $node->{parent} and $node->{parent}->{type} eq "unary_op") {
# 			$line = "   " x ($level) . "  +" . "---" . "($node->{value})\n";
			$line = "   " x ($level) . "  +" . "---" . "($node->{value}) $node->{id}\n";
			print $line | $lines;
		}

		if ($node->{type} eq "binary_op") {
			tree_dumper($node->{left}, $level+1, @lines, $level);
			tree_dumper($node->{right}, $level+1, @lines);
		}
		elsif ($node->{type} eq "unary_op") {
			tree_dumper($node->{operand}, $level+1);
		}
	}

	set_parent($eq->{trees}->{left_side});
	set_parent($eq->{trees}->{right_side});

	print "\n";
	tree_dumper($eq->{trees}->{left_side}, 0);
	print "  =\n";
	tree_dumper($eq->{trees}->{right_side}, 0);
}


# london@archlinux:~/perl/scripts/equations/module
# $ ./equations.pl 'y=3^x,x,y=1'
# y = 3^x
# x = ln(y)/ln(3)
# x = ln(1)/ln(3)
# x = 0
# FALSE
# 
# ------(x)
#   =
# ------(/)
#      L---(ln)
#         +---(1)
#      R---(ln)
#         +---(3)
# 


1;

