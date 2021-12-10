#!/usr/bin/perl


# IDEMPOTENT ???

use strict;
use warnings;
use autodie;
use Encode;
@ARGV = map { decode("UTF-8", $_)  } @ARGV;
binmode STDIN,  ":encoding(UTF-8)";	# bad practice because STDIN and STDOUT are global filehandles
binmode STDOUT, ":encoding(UTF-8)";

exit unless @ARGV;

local $\="\n";
my @sub_array;
my $sub;
my $inplace = 0;
my $OUTPUT;

if ($ARGV[0] eq "-i") {
	$inplace = 1;
	shift;
	exit unless @ARGV;
}

my $file = $ARGV[0];

# known bug when the file contains a Byte Order Mark (BOM)
# foreach (@ARGV) {
foreach ($ARGV[0]) {
	next unless -e $_;
	my $file = quotemeta $_;
# 	unless (grep {/no_bom/} qx{dos2unix --info "$_"} ) {
	unless (grep {/no_bom/} qx{dos2unix --info $file} ) {
		system "dos2unix", "--remove-bom", $_;
# 		system "dos2unix", "--remove-bom", $file;
	}
	if ($? != 0) {
		die "error with dos2unix\n";
	}
}

while (<ARGV>) {
	
	if(/^(\d+)\s*$/) {
		#push the previous sub element when a new element begin
 		if (defined $sub->{text}) {
			chomp $sub->{text};
			push @sub_array, $sub;
		}
		$sub = {};

		#first index
		chomp;
		$sub->{index} = $1;
		next;
	}
	#skip lines until first subtitle
	next unless defined $sub->{index};

	if(/^(\d\d:\d\d:\d\d[.,]\d\d\d) --> (\d\d:\d\d:\d\d[.,]\d\d\d)/) {
		$sub->{start} = $1;
		$sub->{end}   = $2;
	}
	else {
		$sub->{text} .= $_;
	}
}
push @sub_array, $sub;	# last subtitle element

if ($inplace) {
	print STDERR "inplace editing";
	open $OUTPUT, ">", $file;
}
else {
	open $OUTPUT, ">&", *STDOUT;
}

my $idx=1;
foreach (@sub_array) {
	print $OUTPUT $idx;
	print $OUTPUT "$_->{start} --> $_->{end}" if defined $_->{start};
	print $OUTPUT "$_->{text}";
	$idx++;
}

close $OUTPUT;


