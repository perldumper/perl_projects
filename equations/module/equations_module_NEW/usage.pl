#!/usr/bin/perl

use strict;
use warnings;
use lib ".";
# use System;
use Equation;
use dd;

local $,="";
local $\="\n";


my $eq = Equation->new("y=x+1");
# dd $eq;
print $eq->new_stringify;
print $eq->old_stringify;

# my $sys = System->new(equations => ["y=2*x", "y=x+1"]);
# dd $sys;

# my $eq = Equation->new("y=x+1");
# my $eq2 = $eq->copy;
# dd $eq;
# dd $eq2;
# $eq->{trees}{right_side}{right}{value} = 2;
# dd $eq;
# dd $eq2;

# print Dumper $eq2;

# my $eq = Equation->new("a+b+c=d*e");
# my $eq = Equation->new("a=d*e");
# my $eq = Equation->new("vi=(Vm*S)/(Km+S)");
# 
# dd $eq;
# exit;
# 
# $eq->isolate(variable => "d");
# $eq->isolate(variable => "Vm");
# dd $eq;
# 

__END__


my @tests = (
    ["a+b+c=d*e, c=f+g,d,g=78,a=1,b=1,e=1,f=1", ""],
    ["c*(d-e)/((f-g)-a*b)=(z-x)*(y+u) , e, c=1,d=2,f=3,g=4,a=h-3*(i+k),h=5,i=6,k=7,b=8,z=4,x=2,y=2,u=2", ""],
    ["y=x^2,x,y=64", ""],
    ["y=x^3,x,y=729", ""],
    ["y=x^4,x,y=256", ""],
    ["y=exp(x*ln(2)),x,y=256", ""],
    ["y=exp(x+1),x,y=256", ""],
    ["y= ln(x+1),x,y=10", ""],
    ["y=x^(5+5),x,y=1", ""],
    ["y=x^(5+5),x,y=1024", ""],
    ["y=3^x,x,y=1", ""],
    ["y=2^3^x,x,y=2", ""],
);

