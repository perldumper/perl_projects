#!/usr/bin/perl

use strict;
use warnings;
use filter;
use File::Basename;
use Cwd qw(cwd abs_path);
use Encode;
# use Encode qw(decode);
@ARGV = map { decode "UTF-8", $_ } @ARGV;

no warnings "utf8";
binmode STDIN,  ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";

$\="\n";
my $cwd = cwd();
my $dirname;
my $FH;

# my $video = qr/\.(?:mp4|mkv|webm|avi|ts|mpe?g|m4v|flv|wmv)$/;
# my @files = grep { /$video/ } `ls`;
# my @files = grep { /$filetype_re{video}/ } `ls`;
my @files = filter {file_types => ["video"], sort => 1 }, `ls`;
my @history;

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
	@history = map { s/^ \s* \d+ \*? \s+ //rx } <STDIN>;
	foreach (reverse @history) {
		if (m/^mpv /) {
 			$last = $_;
 			last;
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
	print $following;		# print on STDOUT so that the bash wrapper will get the filename from STDIN
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


