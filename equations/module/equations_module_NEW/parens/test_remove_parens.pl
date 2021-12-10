#!/usr/bin/perl

use strict;
use warnings;
use Set::CrossProduct;
use Math::Combinatorics;
use bigrat;
use lib "/home/london/perl/scripts/equations/module/equations_module_NEW/";
use Equation;

local $,="";
local $\="\n";

my %precedence = (
	"**"  => 3,
	"*"   => 2,
	"/"   => 2,
	"+"   => 1,
	"-"   => 1,
);

my %left_associative = (
	"*"   => 1,
	"/"   => 1,
	"+"   => 1,
	"-"   => 1,
	"**"  => 0,
);

my %right_associative = (
	"*"   => 1,
	"/"   => 0,
	"+"   => 1,
	"-"   => 0,
	"**"  => 1,
);

# a OP b OP c
# (a OP b) OP c
# a OP (b OP c)
# a OP b OP c OP d
# (a OP b OP c) OP d
# a OP (b OP c OP d)

my @numbers = (1, 2, 3, 4, 5);

sub test_equality_2_left {
    my ($op1, $op2) = @_;
    my ($a, $b, $c);
    my ($with_paren, $without_paren);
    my $res;

    for my $combine (combine(3, @numbers)) {
        for my $permute (permute($combine->@*)) {
            ($a, $b, $c) = $permute->@*;

#             if ("Inf" eq do {
#             if (10E10 < do {
#                 no bigrat;
#                 eval "\$res =  \$a $op1 \$b  $op2 \$c";
#                 $res;
#             }) {
#                 return "Inf";
#             }

            eval "\$with_paren    = (\$a $op1 \$b) $op2 \$c";
            eval "\$without_paren =  \$a $op1 \$b  $op2 \$c";
            if ($with_paren != $without_paren) {
                return 0
            }
        }
    }
    return 1;
}

sub test_equality_2_right {
    my ($op1, $op2) = @_;
    my ($a, $b, $c);
    my ($with_paren, $without_paren);
    my $res;

    for my $combine (combine(3, @numbers)) {
        for my $permute (permute($combine->@*)) {
            ($a, $b, $c) = $permute->@*;

#             if ("Inf" eq do {
#             if (10E10 < do {
#                 no bigrat;
#                 eval "\$res =  \$a $op1 \$b  $op2 \$c";
#                 $res;
#             }) {
#                 return "Inf";
#             }

            eval "\$with_paren    =  \$a $op1 (\$b $op2 \$c)";
            eval "\$without_paren =  \$a $op1  \$b $op2 \$c";
            if ($with_paren != $without_paren) {
                return 0
            }
        }
    }
    return 1;
}

sub test_equality_3_left {
    my ($op1, $op2, $op3) = @_;
    my ($a, $b, $c, $d);
    my ($with_paren, $without_paren);
    my $res;

    for my $combine (combine(4, @numbers)) {
        for my $permute (permute($combine->@*)) {
            ($a, $b, $c, $d) = $permute->@*;

#             if ("Inf" eq do {
            if (10E10 < do {
                no bigrat;
                eval "\$res =  \$a $op1 \$b  $op2 \$c $op3 \$d";
                $res;
            }) {
                return "Inf";
            }

            eval "\$with_paren    = (\$a $op1 \$b $op2 \$c) $op3 \$d";
            eval "\$without_paren =  \$a $op1 \$b $op2 \$c  $op3 \$d";
            if ($with_paren != $without_paren) {
                return 0
            }
        }
    }
    return 1;
}

sub test_equality_3_right {
    my ($op1, $op2, $op3) = @_;
    my ($a, $b, $c, $d);
    my ($with_paren, $without_paren);
    my $res;

    for my $combine (combine(4, @numbers)) {
        for my $permute (permute($combine->@*)) {

            ($a, $b, $c, $d) = $permute->@*;

#             if ("Inf" eq do {
            if (10E10 < do {
                no bigrat;
                eval "\$res =  \$a $op1 \$b  $op2 \$c $op3 \$d";
                $res;
            }) {
                return "Inf";
            }

            eval "\$with_paren    =  \$a $op1 (\$b $op2 \$c $op3 \$d)";
            eval "\$without_paren =  \$a $op1  \$b $op2 \$c $op3 \$d";
            if ($with_paren != $without_paren) {
                return 0
            }
        }
    }
    return 1;
}


my @ops = qw(+ - * / **);
my $tuple;
my $iterator;
my ($op1, $op2, $op3);
my ($paren_expr, $noparen_expr);

my $format_equality   = " %-20s ==   %s\n";
my $format_inequality = " %-20s !=   %s\n";
my $format_unknown    = " %-20s ??   %s\n";

my $ret;
my $i = 0;

my $eq;

$iterator = Set::CrossProduct->new([\@ops, \@ops]);
while (defined ($tuple=$iterator->get)) {
    ($op1, $op2) = $tuple->@*;
    $paren_expr = "(a $op1 b) $op2 c";
    $noparen_expr = $paren_expr =~ tr/()//dr;
#     print $paren_expr;
    
    $ret = test_equality_2_left($op1, $op2);
#     print "" if $i++ % 5 == 0;
    print "-"x40 if $i++ % 5 == 0;


      $ret == 1     ? printf($format_equality,   $paren_expr, $noparen_expr)
    : $ret == 0     ? printf($format_inequality, $paren_expr, $noparen_expr)
    : $ret eq "Inf" ? printf($format_unknown,    $paren_expr, $noparen_expr)
    : ();

    $paren_expr =~ s/\*\*/^/g;
    $eq = Equation->new("x = $paren_expr");
    print $eq->old_stringify;
    print $eq->new_stringify;
    print "";
#     last;
}

# exit;
$iterator->reset_cursor;
while (defined ($tuple=$iterator->get)) {
    ($op1, $op2) = $tuple->@*;
    $paren_expr = "a $op1 (b $op2 c)";
    $noparen_expr = $paren_expr =~ tr/()//dr;
#     print $paren_expr;

    $ret = test_equality_2_right($op1, $op2);

    print "-"x40 if $i++ % 5 == 0;

      $ret == 1     ? printf $format_equality,   $paren_expr, $noparen_expr
    : $ret == 0     ? printf $format_inequality, $paren_expr, $noparen_expr
    : $ret eq "Inf" ? printf $format_unknown,    $paren_expr, $noparen_expr
    : ();

    $paren_expr =~ s/\*\*/^/g;
    $eq = Equation->new("x = $paren_expr");
    print $eq->old_stringify;
    print $eq->new_stringify;
    print "";

}
# exit;

$iterator = Set::CrossProduct->new([\@ops, \@ops, \@ops]);
while (defined ($tuple=$iterator->get)) {
    ($op1, $op2, $op3) = $tuple->@*;
    $paren_expr = "(a $op1 b $op2 c) $op3 d";
    $noparen_expr = $paren_expr =~ tr/()//dr;
#     print $paren_expr;

    $ret = test_equality_3_left($op1, $op2, $op3);

#     print "" if $i++ % 5 == 0;
    print "-"x40 if $i++ % 5 == 0;

      $ret == 1     ? printf $format_equality,   $paren_expr, $noparen_expr
    : $ret == 0     ? printf $format_inequality, $paren_expr, $noparen_expr
    : $ret eq "Inf" ? printf $format_unknown,    $paren_expr, $noparen_expr
    : ();

    $paren_expr =~ s/\*\*/^/g;
    $eq = Equation->new("x = $paren_expr");
    print $eq->old_stringify;
    print $eq->new_stringify;
    print "";

}
$iterator->reset_cursor;
while (defined ($tuple=$iterator->get)) {
    ($op1, $op2, $op3) = $tuple->@*;
    $paren_expr = "a $op1 (b $op2 c $op3 d)";
    $noparen_expr = $paren_expr =~ tr/()//dr;
#     print $paren_expr;

    $ret = test_equality_3_right($op1, $op2, $op3);

#     print "" if $i++ % 5 == 0;
    print "-"x40 if $i++ % 5 == 0;

      $ret == 1     ? printf $format_equality,   $paren_expr, $noparen_expr
    : $ret == 0     ? printf $format_inequality, $paren_expr, $noparen_expr
    : $ret eq "Inf" ? printf $format_unknown,    $paren_expr, $noparen_expr
    : ();

    $paren_expr =~ s/\*\*/^/g;
    $eq = Equation->new("x = $paren_expr");
    print $eq->old_stringify;
    print $eq->new_stringify;
    print "";

}




__END__

