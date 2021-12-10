#!/usr/bin/perl

use strict;
use warnings;

local $,="";
local $\="\n";




__END__

tokenize
LABEL
while not leaf, push @stack, (plus push index id array) (2nd stack?)
if leaf, print @stack + leaf, pop stack
goto LABEL (outter while loop)



