#!/usr/bin/perl
#
#
# london@archlinux:~/Videos_INFORMATICS/sml/why_you_should_car
# $ vl
#  Why You Should Care About SML Part 1-ymkXsFgq_ps.mp4
#  Why You Should Care About SML Part 2-78S0xDZRZuY.mp4
#  Why You Should Care About SML Part 3-G1U6Wl-t0X0.mp4
#  Why You Should Care About SML Part 4-aEdiXd68PU0.mp4
#  Work Smarter, not Harder and CS--UaX_CdeD_k.mp4
# london@archlinux:~/Videos_INFORMATICS/sml/why_you_should_car
# $ first
# Use of uninitialized value in subroutine entry at /home/lond
# 000.
# cwd and dirname differ
# $cwd /home/london/Videos_INFORMATICS/sml/why_you_should_care
# $dirname /home/london/Videos_INFORMATICS/sml
# Why You Should Care About SML Part 1-ymkXsFgq_ps.mp4

use strict;
use warnings;
use filter;
use File::Basename;
use Cwd qw(cwd abs_path);
use Encode;
@ARGV = map { decode "UTF-8", $_ } @ARGV;

# no warnings "utf8";
open my $IN, "<&:encoding(UTF-8)", *STDIN;
open my $OUT, ">&:encoding(UTF-8)", *STDOUT;

local $\="\n";
my $cwd = cwd();
my $dirname;
my $FH;

opendir my $DIR, "./";
my @files = filter {file_types => ["video"], sort => 1 }, readdir $DIR;
my @history;
closedir $DIR;

my $last;
my $following;

if (-e "./.current") {
	open $FH, "<:encoding(UTF-8)", "./.current";
	$last = <$FH>;
	close $FH;
	chomp $last if defined $last;
	$dirname = cwd();
}
else {
	@history = map { s/^ \s* \d+ \*? \s+ //rx } <$IN>;
	foreach (reverse @history) {
		if (m/^mpv /) {
 			$last = $_;
 			last;
            # check if the file is in the current directory
            # absolute path --> basename eq $cwd
            # realtive path --> $cwd/filename exists
 		}
 	}
	if (defined $last) {
		($last) = $last =~ m/^mpv "(.*?)"/;			# FIRST $last
		$dirname = dirname(abs_path($last));		# FIRST $last
	}
}


if ($ARGV[0] eq "first") {
	chomp ($following = $files[0]);				# FIRST $following
}
elsif ($ARGV[0] eq "last") {
	chomp ($following = $files[-1]);
}
elsif ($ARGV[0] eq "curr") {
	$following = $last;
}
elsif ($ARGV[0] eq "succ") {
	for (my $i=0; $i < @files; $i++){
		if ($files[$i] =~ m/\Q$last\E/) {
			if ($i == $#files) {
				chomp ($following = $files[-1]);
 				last;
 			}
 			else {
 				chomp ($following = $files[$i+1]);
 				last;
 			}
 		}
	}
}
elsif ($ARGV[0] eq "pred") {
	for (my $i=0; $i < @files; $i++){
		if ($files[$i] =~ m/\Q$last\E/) {
			if ($i == 0) {
				chomp ($following = $files[0]);
				last;
			}
			else {
				chomp ($following = $files[$i-1]);
				last;
			}
		}
	}
}

if (defined $following) {
	print $OUT $following;
	if ($cwd eq $dirname) {	# check if
		open $FH, ">:encoding(UTF-8)", "./.current";
		print $FH $following;	# save the name of the file played so that we now where we are in the playlist
		close $FH;
	}
	else {
		print STDERR "cwd and dirname differ";
		print STDERR "\$cwd $cwd";
		print STDERR "\$dirname $dirname";
	}
#	if (@ARGV) {
#		print STDERR "\"$following\"" if $ARGV[1] eq "--debug;"
#	}
}

close $IN;
close $OUT;



