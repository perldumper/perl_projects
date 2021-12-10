#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use v5.10;

my $extract_pics = 0;

if (not @ARGV) { exit }
elsif ($ARGV[0] =~ /^--?pics/) {
	$extract_pics = 1;
	shift @ARGV;
}
binmode STDOUT, ":encoding(UTF-8)";

$\="\n";
# $,="\n";
# $,=" ";
$,="";
my $FH;
my $bytes;
my ($file_identifier, $version, $flags, $size);
my ($frame_id, $text);
my $picture;
my $mimetype;
my $skip_byte;
my $pic_number = 1;

my $total_size = 0;

open $FH, "<:raw", $ARGV[0];

$ARGV[0] =~ s/\.[^.]+$//;

# tag header				# discard the tag header
read $FH, $bytes, 10;
$total_size += 10;
# ($file_identifier, $version, $flags, $size) = unpack "a3 hh N Z4", $bytes;
say 10;
say "tag header\n";

# http://id3lib.sourceforge.net/id3/id3v2.3.0.html
my %frames = (
	AENC => "Audio encryption",
	APIC => "Attached picture",
	COMM => "Comments",
	COMR => "Commercial frame",
	ENCR => "Encryption method registration",
	EQUA => "Equalization",
	ETCO => "Event timing codes",
	GEOB => "General encapsulated object",
	GRID => "Group identification registration",
	IPLS => "Involved people list",
	LINK => "Linked information",
	MCDI => "Music CD identifier",
	MLLT => "MPEG location lookup table",
	OWNE => "Ownership frame",
	PRIV => "Private frame",
	PCNT => "Play counter",
	POPM => "Popularimeter",
	POSS => "Position synchronisation frame",
	RBUF => "Recommended buffer size",
	RVAD => "Relative volume adjustment",
	RVRB => "Reverb",
	SYLT => "Synchronized lyric/text",
	SYTC => "Synchronized tempo codes",
	TALB => "Album/Movie/Show title",
	TBPM => "BPM (beats per minute)",
	TCOM => "Composer",
	TCON => "Content type",
	TCOP => "Copyright message",
	TDAT => "Date",
	TDLY => "Playlist delay",
	TENC => "Encoded by",
	TEXT => "Lyricist/Text writer",
	TFLT => "File type",
	TIME => "Time",
	TIT1 => "Content group description",
	TIT2 => "Title/songname/content description",
	TIT3 => "Subtitle/Description refinement",
	TKEY => "Initial key",
	TLAN => "Language(s)",
	TLEN => "Length",
	TMED => "Media type",
	TOAL => "Original album/movie/show title",
	TOFN => "Original filename",
	TOLY => "Original lyricist(s)/text writer(s)",
	TOPE => "Original artist(s)/performer(s)",
	TORY => "Original release year",
	TOWN => "File owner/licensee",
	TPE1 => "Lead performer(s)/Soloist(s)",
	TPE2 => "Band/orchestra/accompaniment",
	TPE3 => "Conductor/performer refinement",
	TPE4 => "Interpreted, remixed, or otherwise modified by",
	TPOS => "Part of a set",
	TPUB => "Publisher",
	TRCK => "Track number/Position in set",
	TRDA => "Recording dates",
	TRSN => "Internet radio station name",
	TRSO => "Internet radio station owner",
	TSIZ => "Size",
	TSRC => "ISRC (international standard recording code)",
	TSSE => "Software/Hardware and settings used for encoding",
	TYER => "Year",
	TXXX => "User defined text information frame",
	UFID => "Unique file identifier",
	USER => "Terms of use",
	USLT => "Unsychronized lyric/text transcription",
	WCOM => "Commercial information",
	WCOP => "Copyright/Legal information",
	WOAF => "Official audio file webpage",
	WOAR => "Official artist/performer webpage",
	WOAS => "Official audio source webpage",
	WORS => "Official internet radio station homepage",
	WPAY => "Payment",
	WPUB => "Publishers official webpage",
	WXXX => "User defined URL link frame",
);


# first frame header
read $FH, $bytes, 10;			# 10 is the size in bytes of the frame headers of ID3 tag
$total_size += 10;
($frame_id, $size, $flags) = unpack "a4 N4 a2", $bytes;
say "FRAME --> $frame_id";

while (grep {/$frame_id/} keys %frames) {
# 	last if $frame_id eq "APIC";
    # read content of the current frame
	read $FH, $bytes, $size;
    $total_size += $size;

	if ($frame_id eq "APIC") {
        say "PICTURE";

		($skip_byte) = unpack "x a*", $bytes;
		($mimetype, $picture) = unpack "Z* xx a*", $skip_byte;

		if ($extract_pics) {
			local $\="";
			open my $PICTURE, ">:raw", "$ARGV[0]-$pic_number.jpeg";
			print $PICTURE $picture;
			close $PICTURE;
			local $\="\n";
		}
		say 10;
		say $size;
		say $frames{APIC};
		say "pic number = $pic_number";
		$pic_number++;

		next;
	}
	($text) = unpack "a*", $bytes;
	$text =~ tr/\x00//d;
	print 10;
	print $size;
	print $frames{$frame_id}, "\n", $text, "\n";

} continue {
	read $FH, $bytes, 10;			# 10 is the size in bytes of the frame headers of ID3 tag
    $total_size += 10;
	($frame_id, $size, $flags) = unpack "a4 N4 a2", $bytes;
    say "FRAME --> $frame_id";
}

say "total size = $total_size";


close $FH;

__END__


sub set_product {		# cartesian product of n sets
	my @array_of_aref = @_;
	if (@array_of_aref == 0) {
		return;
	}
	elsif (@array_of_aref == 1) {
		return $array_of_aref[0];
	}
	elsif (@array_of_aref >= 2) {
		my $array_a = shift @array_of_aref;
		my $array_b = shift @array_of_aref;
		my @array_c;
		foreach my $a ($array_a->@*) {
			foreach my $b ($array_b->@*) {
				if (ref $a eq "" and ref $b eq "") {
					push @array_c, [$a,     $b];
				}
				elsif (ref $a eq "ARRAY" and ref $b eq "") {
					push @array_c, [$a->@*, $b];
				}
				elsif (ref $a eq "" and ref $b eq "ARRAY") {
					push @array_c, [$a,     $b->@*];
				}
				elsif (ref $a eq "ARRAY" and ref $b eq "ARRAY") {
					push @array_c, [$a->@*, $b->@*];
				}
			}
		}
		while (my $aref = shift @array_of_aref) {
			@array_c = set_product(\@array_c, $aref);
		}
		return @array_c;
	}
}

my $template;

close STDERR;

foreach (set_product(
# [qw(a A Z b B h H c C W s S l L q Q i I n N v V j J f d F D p P u U w x X @ . )],
# [qw(a A Z b B h H c C W s S l L q Q i I n N v V j J f d F D p P u U w x X @ . )]) )
# [qw(a A Z b B h H c C W s S l L q Q i I n N v V j J f d F p P u U w x X @ . )],
# [qw(a A Z b B h H c C W s S l L q Q i I n N v V j J f d F p P u U w x X @ . )]) )
[qw(a A Z b B h H c C W q Q n N v V j J p P u U w X .)],
[qw(a A Z b B h H c C W q Q n N v V j J p P u U w X .)]) )
{
	$template = "a3 hh $_->[0] $_->[1]4";
	seek $FH, 0, 0;
	read $FH, $bytes, 10;
	($file_identifier, $version, $flags, $size) = unpack $template, $bytes;

	next if $size eq "0";
	next if $size == 0;
	next if $size == 1;
	next if $size == 5;
	next if $size == 338;
	next if $size == 1375797248;
	print "#" x 30, $template;
	print $file_identifier, $version, $flags, $size;
	

}

# foreach (1..4) {
# 	seek $FH, 0, 0;
# 	read $FH, $bytes, 10;
# 	($file_identifier, $version, $flags, $size) = unpack "a3 hh N Z4", $bytes;
# 	print $file_identifier, $version, $flags, $size;
# }







 00 01  52 02

1 * 256*16 + 5 * 256*256 + 2 * 256*256*16  + 2 * 256*256*256*16

= 35983360

*  4= 14393344

--------------------------------------------------------
 00 01  52 02

1 * 256*256  + 5 * 256*16  + 2 * 256  + 2

= 86530
346120


--------------------------------------------------------


1*256 + 2*256*256 + 5*256*256*16 + 2*256*256*256
=38928640
--------------------------------------------------------



