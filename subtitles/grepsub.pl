#!/usr/bin/perl
#
# $ grepsub 'moriarty' *.srt
# UTF-8 "\xA3" does not map to Unicode at /home/london/.my_configurations/scripts/perl/subtitles/grepsub.pl line 102, <$_[...]> line 431.
# UTF-8 "\xA3" does not map to Unicode at /home/london/.my_configurations/scripts/perl/subtitles/grepsub.pl line 78, <$_[...]> line 3860.
# UTF-8 "\xA3" does not map to Unicode at /home/london/.my_configurations/scripts/perl/subtitles/grepsub.pl line 102, <$_[...]> line 4081.
# A Study in Pink.srt:1166
# 01:21:19,920 --> 01:21:23,600
# Moriarty!
# 
# A Study in Pink.srt:1265
# -----------------------------------------------------------------------------------------------------

# TO DO

# prefix the name of the file is there is several files
# put it in color purple like grep
# echo -e "\e[00;35mgrepsub.pl\e[00m"
# add some features that grep has like:
# -A after
# -B before
# -C context -> before and after

# e[35m[Kgrepsub.pl[m[K[36m[K:[m[K[32m[K1[m[K[36m[K:[m[K#!/usr/bin/[01;31m[Kperl[m[ub.pl
# grep --color=always -rni 'perl' | vim -

# detect if vtt, and if so, convert with vttbytwo

# detect if bom mark with hexdump / unpack "C20" ???
# at least package actual check into a function

# this script allows for grepping both srt and vtt subtitles

use strict;
use warnings;
use autodie;
use Encode;
@ARGV = map { decode("UTF-8", $_)  } @ARGV;
binmode STDIN, ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";

use constant MAGENTA => "\e[35m";
use constant    CYAN => "\e[36m";
use constant   GREEN => "\e[32m";
use constant   RESET => "\e[0m";
use constant    BOLD => "\e[1m";
use constant     RED => "\e[31m";

sub help {
    print STDERR <<~'EOF';
    grepsub PATTERN FILES
    EOF
}

unless (@ARGV) {
    help();
    exit;
}

my $sub = "";
my $index;
my @files;
my $file_no = 0;
our $match_count = 0;
our $file_count = 0;
our %matching_files;
# my $pattern = shift @ARGV;
my $pattern;
# exit unless @ARGV;
my $filename = 0;

foreach (@ARGV) {
    if (/^--filename$/) {
        $filename = 1;
        shift
    }
    else {
        $pattern = shift;
        last;
    }
}


# known bug when the file contains a Byte Order Mark (BOM)
foreach (@ARGV) {
	next unless -e $_;
	my $file = quotemeta $_;
# 	unless (grep {/no_bom/} qx(dos2unix --info "$_")) {
	unless (grep {/no_bom/} qx(dos2unix --info $file)) {
# 		system "dos2unix", "--remove-bom", $_;  # CURRENT
# 		system "dos2unix", "--remove-bom", $file;
	}
	if ($? != 0) {
		die "error with dos2unix\n";
	}
}

foreach (@ARGV) {
	push @files, { filename => $_ };
# }

# while (<ARGV>) {

open my $FH, "<:encoding(UTF-8)", $_;	# new
while (<$FH>) {				# new

	s/<.*?>//g;
	s/^(\d\d:\d\d:\d\d[.,]\d\d\d --> \d\d:\d\d:\d\d[.,]\d\d\d).*/$1/;

	if ( m/^(\d+)\s*$/) {
		$index = $1;
		next;
	}

	if (/^\d\d:\d\d:\d\d[.,]\d\d\d --> \d\d:\d\d:\d\d[.,]\d\d\d/) {
		#flush: push the previous sub element when a new element begin
 		chomp $sub				if $sub ne "" ;
		push $files[$file_no]->{subs}->@*, $sub	if $sub ne "";
		$sub = "";
		$sub = $index . "\n" if defined $index;		# if srt subtitles
		$sub .= $_;
		$index = undef;
		next;
	}

	next if $sub eq "";
	$sub .= $_ unless /^\s*$/;

	if (eof) {
		push $files[$file_no]->{subs}->@*, $sub	if $sub ne "";
		$sub = "";
		$file_no++;
	}
}				# new
	close $FH;	# new
}


sub print_grep_color {
	my ($pattern, $color, $filename) = (shift,shift,shift);
	my $line;
	my @pos;
	my $i;
	local $\="";
	local $,="";	

# 	while ($line = shift @_) {
	while (defined ($line = shift @_)) {
		chomp $line;
		@pos = ();
		while ($line =~ /($pattern)/ig) {	# find positions of all matches in a line
			push @pos, [$-[0], $+[0]];		# and foreach, push start and end positions in the line
		}
		if (@pos) {							# if at least one match in the current line
			$match_count++;
			$matching_files{$filename}++;
			# replicate grep output when mutliple files + -n flag :
			# print MAGENTA, $filename, CYAN, ":", GREEN, $., CYAN, ":", RESET;
			if ($filename) {
				chomp $filename;
				if ($color) {
					print MAGENTA, $filename, CYAN, ":", RESET;
				}
				else {
					print $filename . ":";
				}
			}
			if ($color) {
				print substr $line, 0, $pos[0]->[0];                                                     # before first match
				for($i=0; $i < @pos; $i++) {
					print BOLD, RED, substr($line, $pos[$i]->[0], $pos[$i]->[1] - $pos[$i]->[0]), RESET; # match
					if ($pos[$i+1]) {
						print      substr $line, $pos[$i]->[1], $pos[$i+1]->[0] - $pos[$i]->[1];         # in-between matches
					}
				}
				print substr($line, $pos[-1]->[1], length $line) . "\n\n";                               # after last match
			}
			else {
				print $line . "\n\n";
			}
		}

	}
}

my $color;
if (-t STDOUT) { $color = 1 }
else           { $color = 0 }

if (@files == 1 && ! $filename) {
	print_grep_color($pattern, $color, 0, $files[0]->{subs}->@*);
	print "$match_count subtitles match\n";
}
elsif ($filename) {
	foreach (@files) {
		$matching_files{$_} = 0;
		print_grep_color($pattern, $color, $_->{filename}, $_->{subs}->@*);
	}
	$file_count = () = grep { $matching_files{$_} > 0 } keys %matching_files;
	print "$match_count subtitles match in $file_count files\n";
}
else {
	foreach (@files) {
		$matching_files{$_} = 0;
		print_grep_color($pattern, $color, $_->{filename}, $_->{subs}->@*);
	}
	$file_count = () = grep { $matching_files{$_} > 0 } keys %matching_files;
	print "$match_count subtitles match in $file_count files\n";
}


