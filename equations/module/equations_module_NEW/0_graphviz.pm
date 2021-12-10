
package graphviz;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
		make_graphviz_tree
		make_graphviz_graph
		print_graphviz
		print_graphviz_notemp
		print_graphviz_tmpfs
);


# take from another script
# sub make_graph_file {
#     my $trie = shift;
# 
#     my $graph = GraphViz2->new(
#         edge => {color => "black"},
#         global => {directed => 1},
#         graph => {rankdir => "LR"},
#         node => {shape => "circle"},
#     );
# 
#     my $id = 0;
#     my $add_edges;
#    $add_edges = sub {
#         my $tree = shift;
#         my $from = $id;     # id of parent node
#         foreach my $node (sort grep { $_ ne "" } keys $tree->%*) {
#             $id++;
#             $graph->add_node(name => $id, label => $node);
#             $graph->add_edge(from => $from, to => $id);
#             $add_edges->($tree->{$node});
#         }
#     };
# 
# 
#     $graph->add_node(name => $id, label => "watch?v=");  # root of the trie
#     $add_edges->($trie);
#     my $format      = shift || 'svg';
#     my $output_file = shift || "trie.$format";
#     my $output_file = shift || "trie2.$format";
#     my $output_file = shift || "dico.$format";
#     $graph->run(format => $format, output_file => $output_file);
# }



####################
#     GRAPHVIZ     #
####################

sub make_graphviz_tree {
	my $eq = shift;
	################
# 	$eq = copy_data_structure($eq);
# 	delete $eq->{nodes};
# 	delete $eq->{graph};
# 	#mark_nodes($eq);
# 	mark_nodes2($eq);
# 	#mark_nodes3($eq);
# 	make_graph($eq);
# 	$eq->{nodes}->%* = find_nodes($eq);

# 	foreach my $node_id (grep {$eq->{nodes}->{$_}->{type} ne "operator"} keys $eq->{nodes}->%*) {
# 		isolate(node=> 1, which=> $node_id, equation=> $eq);
# 		make_graph($eq);
# 	}

	##################
	my @graphviz;
	push @graphviz, "digraph G {\n";
	foreach my $node (sort keys $eq->{nodes}->%*) {
		push @graphviz, "$node [label = \"$eq->{nodes}->{$node}->{value}\"]\n";
	}
	foreach my $from (sort keys $eq->{graph}->%*) {
		foreach my $to (sort $eq->{graph}->{$from}->@*) {
			push @graphviz, "$from -> $to\n";
		}
	}
	push @graphviz, "}\n";
	return @graphviz;
}

sub make_graphviz_graph {
}



sub print_graphviz_notemp {
	my @graph = @_;
	my $file = "equation-graph";
	open my $FH, ">", "$file.dot" || die "$!";
	print $FH @graph;
	close $FH;
	system "dot -Tpng $file.dot >> $file.png";
	system "sxiv $file.png &";	# image viewer
	unlink "$file.dot";
# 	usleep "50000";				# sleep for 50 milliseconds
	unlink "$file.png";
}



sub print_graphviz {
	my @graph = @_;
	my ($fh, $tmp)=tempfile();
	die "cannot create tempfile" unless $fh;
	print ($fh @graph ) || die "write temp: $!";
	close $fh;
	open my $FH, "<", $tmp || die "$!";
	close $FH;
	system "dot -Tpng $tmp >> $tmp.png";
	system "sxiv $tmp.png &";	# image viewer
	unlink($tmp);
# 	usleep "70000";				# sleep for 50 milliseconds
								# this is required to give sxiv the time it need to read the file before it is deleted
	unlink("$tmp.png");
}

# require having this line if /etc/fstab
# tmpfs   /tmp/ram/   tmpfs    defaults,noatime,nosuid,nodev,noexec,mode=1777,size=32M 0 0
# or execute this in a terminal
# mkdir -p /tmp/ram; sudo mount -t tmpfs -o size=32M tmpfs /tmp/ram/

sub print_graphviz_tmpfs {
	my @graph = @_;
# 	system "rm /tmp/ram/* 2> /dev/null";
	my $file = "/tmp/ram/equation-graph";
	open my $FH, ">", "$file.dot" || die "$!";
	print $FH @graph;
	close $FH;
	system "dot -Tpng $file.dot >> $file.png";
	system "sxiv $file.png &";	# image viewer
# 	unlink "$file.dot";
# 	usleep "50000";				# sleep for 50 milliseconds
# 	unlink "$file.png";
}


1;

