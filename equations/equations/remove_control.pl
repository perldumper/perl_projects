#!/usr/bin/perl

use strict;
use warnings;

local $,="\n";
local $\="\n";

my $start_esc_seq = "\x{1B}\x{5B}";				# \e[
my $_0m           = "\x{30}\x{6D}";				# 0m
my $reset_end     = "\x{30}\x{6D}";				# 0m
my $reverse       = "\x{1B}\x{5B}\x{37}\x{6D}";	# \e[7m
my $reset         = "\x{1B}\x{5B}\x{30}\x{6D}";	# \e[0m


my @lines = map { chomp; $_ } <STDIN>;

@lines = map { s/\x{1B}\x{5B}\x{4B}//gr } @lines;	# ^[[K

@lines = map {  s/\x{1B}\x{5B}\x{6D}//rg } @lines;		# ^[[m

@lines =  map { s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m //rgx } @lines;

# print @lines;
print $lines[0];

