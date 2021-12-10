
package Automata;

use strict;
use warnings;

sub new {
    my $class = shift;
    my %automata = @_;
    # states, start_state, end_states, transitions, alphabet

    $automata{accepting}->%* = map { $_ => 0 } $automata{states}->@*;
    $automata{accepting}->{$_} = 1 foreach $automata{end_states}->@*;

    foreach my $from (keys $automata{transitions}->%*) {
        foreach my $input (keys $automata{transitions}->{$from}->%*) {

            my $to = $automata{transitions}->{$from}->{$input};

            push $automata{edges}->{$from}->{$to}->@*, $input
        }
    }

    return bless \%automata, $class;
}

sub make_graph {
    require GraphViz2;
    my $self = shift;
    my $graph = GraphViz2->new(
        edge => {color => "black"},
        global => {directed => 1},
        graph => {rankdir => "LR"},
        node => {shape => "circle"},
    );

    $graph->add_node(name => "to_start", style => "invis");
    foreach my $state ($self->{states}->@*) {
        $graph->add_node(
            name => $state,
            label => $state,
            shape => ($self->{accepting}->{$state}
                ? "doublecircle"
                : "circle"
            ),
        );
    }
    foreach my $from (sort keys $self->{edges}->%*) {
        foreach my $to (sort keys $self->{edges}->{$from}->%*) {

            $graph->add_edge(
                from => $from,
                to => $to,
                label => join ",", sort $self->{edges}->{$from}->{$to}->@*,
            );
        }
    }
    $graph->add_edge(from => "to_start", to => $self->{start_state});
    return $graph;
}

sub print_graph {
    my $self = shift;
    my %options = @_;
    if (not exists $options{format}) {
        die "missing \"format\"";
    }
    if (not exists $options{output_file}) {
        die "missing \"output_file\"";
    }
    my $graph = make_graph($self);

    $graph->run(%options);
}

sub show_graph {
    my $self = shift;

    eval 'use File::Temp "tempfile"';
    my (undef, $filename) = tempfile();
    my $filename_quoted = quotemeta $filename;

    my %options;
    $options{format} = "png";
    $options{output_file} = $filename;

    while (@_) {
        my $key = shift;
        $options{$key} = shift;
    }

    if (not exists $options{format}) {
        die "missing \"format\"";
    }
    if (not exists $options{output_file}) {
        die "missing \"output_file\"";
    }
    my $graph = make_graph($self);
    $graph->run(%options);
    system "sxiv $filename_quoted &";
}


sub run {
    my $self = shift;
    my $string = shift;

    my $state = $self->{start_state};

    foreach my $input (split "", $string) {
        $state = $self->{transitions}->{$state}->{$input};
    }

    return $self->{accepting}->{$state};
}


1;


