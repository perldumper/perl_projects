#!/usr/bin/perl

use strict;
use warnings;
use dd;
use lib ".";
use System;
use Equation;

local $/=undef;
local $,="";
local $\="\n";

my $input;
my $debug = 0;

if (@ARGV) {
	if ($ARGV[0] eq "debug") { shift; $debug = 1 }
	if (-e $ARGV[0]) { $input = <ARGV>  }
	else             { $input = $ARGV[0]}
}
elsif (not -t STDIN) { $input = <STDIN> }
else                 { exit }

my @assertions = map { s/\s+//gr } split ",", $input;
my @equations;
my @knowns;
my @wants;

my $number = qr/ \d+ (?: \.\d+ (?: [eE][+-]\d+ )? )? /x;
my $variable = qr/ [a-zA-Z_][a-zA-Z_0-9]* /x;

while (defined (my $assertion = shift @assertions)) {
    if ($assertion =~ m/=/) {
        if ($assertion =~ m/ ^ $variable = $number $ | ^ $number = $variable $ /x) {
            push @knowns, $assertion;
        }
        else {
            push @equations, $assertion;
        }
    }
    elsif ($assertion =~ m/ ^ $variable $ /x) {
        push @wants, $assertion;
    }
}

print "EQUATIONS";
print join "\n", @equations;
print "KNOWNS";
print join "\n", @knowns;
print "WANTS";
print join "\n", @wants;


my $sys = System->new(equations => \@equations);
dd $sys;

exit;

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

