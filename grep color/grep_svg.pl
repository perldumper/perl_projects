#!/usr/bin/perl

use strict;
use warnings;
# use Term::ANSIColor qw(:constants);		# BOLD RED GREEN, etc..  do not need to be followed by a comma

# perl -le 'print "\e[35m/home/london/wd\e[36m:\e[32m2\e[36m:\e[0m\e[1m\e[31mline\e[0m 2"'

use constant MAGENTA => "\e[35m";
use constant    CYAN => "\e[36m";
use constant   GREEN => "\e[32m";
use constant   RESET => "\e[0m";
use constant    BOLD => "\e[1m";
use constant     RED => "\e[31m";


# -rniI
# -A -B -C


sub _grep {
# 	my ($pattern, @files) = @_;
	my $pattern = shift;
	my $filename = shift;
	my $filehandle = shift;
# 	my $file;
# 	my $FH;
	my $line;
	my @pos;
	my $i;
	local $\="";
	local $,="";	

# 	foreach $file (@files) {
# 		chomp $file;
# 		open $FH, "<", $file;
# 
# 		while ($line = <$FH>) {
# 		while ($line = shift @_) {
		while ($line = <$filehandle>) {
			chomp $line;
			@pos = ();
			while ($line =~ /($pattern)/g) {	# find positions of all matches in a line
				push @pos, [$-[0], $+[0]];		# and foreach, push start and end positions in the line
			}
			if (@pos) {							# if at least one match in the current line
				# replicate grep output when mutliple files + -n flag :
# 				print MAGENTA, $file, CYAN, ":", GREEN, $., CYAN, ":", RESET;
				if ($filename) {
					chomp $ARGV;
					print MAGENTA, $ARGV, CYAN, ":", GREEN, $., CYAN, ":", RESET;
				}
				else {
					print                            GREEN, $., CYAN, ":", RESET;
				}
				print substr $line, 0, $pos[0]->[0];														# before first match

				for($i=0; $i < @pos; $i++) {
					print BOLD, RED, substr($line, $pos[$i]->[0], $pos[$i]->[1] - $pos[$i]->[0]), RESET;	# match
					if ($pos[$i+1]) {
						print      substr $line, $pos[$i]->[1], $pos[$i+1]->[0] - $pos[$i]->[1];			# in-between matches
					}
				}
				print substr $line, $pos[-1]->[1], length $line;											# after last match
				print "\n";
			}

			$. = 0 if eof;
			
		}
# 		close $FH;
# 	}
}

my $pattern = shift @ARGV;

if (@ARGV) { 
	if (-e $ARGV[0]) {
		if (@ARGV == 1) {
			_grep $pattern, 0, *ARGV;
		}
		else {
			_grep $pattern, 1, *ARGV;
		}
	}
	elsif ($ARGV[0] eq "-") {
		local @ARGV = *STDIN;
		_grep $pattern, *ARGV;
	}
}
elsif (not -t STDIN) {
	_grep $pattern, *STDIN;
}




