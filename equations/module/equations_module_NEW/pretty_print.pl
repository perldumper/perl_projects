#!/usr/bin/perl

use strict;
use warnings;
use lib ".";
use Equation;
use Equation::Parser "parse_expression";
use Expression::Stringify qw(tree_to_postfix postfix_to_infix set_parent tree_to_infix);

local $,="";
local $\="\n";

my ($new_stringify, $old_stringify);

foreach my $expr (map { s/\s+//gr } split ",", join "", @ARGV) {

    if ($expr =~ m/=/) {
        my $eq = Equation->new($expr);
        $old_stringify = $eq->old_stringify;
        $new_stringify = $eq->new_stringify;
    }
    else {
        $expr = parse_expression($expr);
        $old_stringify = join "", postfix_to_infix( tree_to_postfix($expr));
	    set_parent($expr);
        $new_stringify = tree_to_infix($expr);
    }

    if ($old_stringify eq $new_stringify) {
        print $new_stringify
    }
    else {
        print "output of methods old_stringify and new_stringify differ";
        print "old_stringify\n$old_stringify";
        print "new_stringify\n$new_stringify";
    }
}    


__END__


