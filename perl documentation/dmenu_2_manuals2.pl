#!/usr/bin/perl

use strict;
use warnings;

my @manuals = `man -k . | grep "(2)" | dmenu -i -l 30`;
# my @manuals = `man -k . |grep "(2)" | dmenu -i -l 30 -fn 'Droid Sans Mono-11'`;

foreach (@manuals) {
	$_=join "", (split /\s+/, $_)[0..1];
	y/(/./;
	y/)//d;
}

foreach (@manuals) {
		#system "xfce4-terminal", "-e", "man $_";
#	system "xfce4-terminal", "-T", "$_ - man 2 System calls", "-e", "man $_";
	system "st -e man $_";
	open FH, ">>", "$ENV{HOME}/.bash_history";
	print FH "man $_\n";
	close FH;
}

#perl -e 'system "xfce4-terminal", "-T", "$_ - man 2 System calls", "-e", "man $_" for map { s/^(\w+)\s+\((.*?)\).*/$1.$2/r } `man -k . | grep "(2)" | dmenu -i -l 30`'
