#!/usr/bin/perl

# IDEMPOTENT ???
# detect if almost all subs are in 3, > 90% or something like that
#


use strict;
use warnings;
use File::Copy;
exit unless @ARGV;

# add dos2unix

my $inplace = 0;
if ($ARGV[0] eq "-i") {
	$inplace = 1;
	shift;
	exit unless @ARGV;
}

my $file = $ARGV[0];
my $sub = "";
my @subs;
my @header;
my $OUTPUT;

open my $FH, "<:encoding(UTF-8)", $file;

# while (<ARGV>) {
while (<$FH>) {
	s/<.*?>//g;
	if (/^(\d\d:\d\d:\d\d[.,]\d\d\d) --> (\d\d:\d\d:\d\d[.,]\d\d\d)/) {
		push @subs, { start => $1, end => $2, lines => [] };
		next;
	}
	if (@subs) {
		chomp;
# 		push $subs[-1]->{lines}->@*, $_ unless /^\s*$/;
		# this suppose that a subtitle element cannot have more than 2 lines, lines beyond the 2nd line are ignored
		push $subs[-1]->{lines}->@*, $_ unless $subs[-1]->{lines}->@* >= 2;
	}
	else {	# lines before first subtitle element
		push @header, $_
	}
}
close $FH;

if ($inplace) {
	copy $file, "./.$file";
	print STDERR "inplace editing\n";
# 	open $OUTPUT, ">", $file;
	open $OUTPUT, ">:encoding(UTF-8)", $file;
}
else {
# 	open $OUTPUT, ">&", *STDOUT;
	open $OUTPUT, ">&:encoding(UTF-8)", *STDOUT;
}

print $OUTPUT @header;

my ($start, $end);
my ($line1, $line2);
my $number_of_subs = @subs;	# because array will be extended when looked up of indexes beyond $#last_index
my $last_start = $subs[-1]->{start};
my $last_end = $subs[-1]->{end};

for (my $i=0; $i < $number_of_subs; $i += 4) {
	$start = $subs[$i + 0]->{start} // $last_start // "(start)";
	$end   = $subs[$i + 4]->{start} // $last_end // "(end)";

	# defined-or operator: usually, a subtitle line appears thrice, but sometimes it is less

	$line1 = $subs[$i + 0]->{lines}[1]
          // $subs[$i + 1]->{lines}[0]
          // $subs[$i + 2]->{lines}[0]
          // "";

	$line2 = $subs[$i + 2]->{lines}[1]
          // $subs[$i + 3]->{lines}[0]
          // $subs[$i + 4]->{lines}[0]
          // "";

	print $OUTPUT "$start --> $end\n";	
	print $OUTPUT "$line1\n";
	print $OUTPUT "$line2\n";
	print $OUTPUT "\n";
}

close $OUTPUT;

