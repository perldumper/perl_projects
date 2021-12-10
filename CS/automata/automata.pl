#!/usr/bin/perl

use strict;
use warnings;
use lib "./";
use Automata;

local $,="";
local $\="\n";

my $automata = Automata->new(
    states => [qw(q1 q2 q3)],
    start_state => "q1",
    end_states => ["q3"],
    alphabet => [0, 1],
    transitions => {
        q1 => {
            0 => "q1",
            1 => "q2",
        },
        q2 => {
            0 => "q1",
            1 => "q3",
        },
        q3 => {
            0 => "q3",
            1 => "q3",
        },
    },
);

# $automata->print_graph(
#     format => "png",
#     output_file => "test.png",
# );
$automata->show_graph;

my @tests = qw(
    000
    000011
    010101
    11
    011
    110
    0101011
);

foreach my $test (@tests) {
    if ($automata->run($test)) {
        print "true\t$test"
    }
    else {
        print "false\t$test"
    }
}


__END__

