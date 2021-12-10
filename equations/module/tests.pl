#!/usr/bin/perl

use strict;
use warnings;

local $,="";
local $\="";

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

my $result;
foreach my $test (@tests) {
    $result = qx{ ./equations.pl "$test->[0]" };
    chomp $result;
    print $test->[0];
    if ($result eq $test->[1]) {
        print "\tOK\n";
    }
    else {
        print "\tFAIL\n";
    }
}

__END__

