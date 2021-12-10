#!/usr/bin/perl

# heuristic to rename subtitle files of a TV serie's season to the name of its corresponding video episode file



# IDEMPOTENT ???

# does not work with movies

# -----------------------------------------------
# DETECT SEPARATOR

# my @chars = $name =~ m/([^a-zA-Z0-9])/g;
# count chars, take the chars with highest number
# most likely '.' or '-'

# my %char_count;
# $char_count{$_}++ for @chars;

# my $separator = 
# (sort { $a->[1] <=> $b->[1] }
# map { [$_, $char_count{$_}] }
# keys %char_count)[-1]->[0];

# my $separator = 
# (sort { $char_count{$a} <=> $char_count{$b} } 
# keys %char_count)[-1];

# perl -le '@chars = shift =~ m/([^a-zA-Z0-9])/g; $char_count{$_}++ for @chars; $separator=(sort { $a->[1] <=> $b->[1] } map { [$_, $char_count{$_}] } keys %char_count)[-1]->[0]; print $separator' 'avengers-age-of-ultron-2015-english-yify-47551'

# perl -le '@chars = shift =~ m/([^a-zA-Z0-9])/g; $char_count{$_}++ for @chars; $separator=(sort { $char_count{$a} <=> $char_count{$b} } keys %char_count)[-1]; print $separator' 'avengers-age-of-ultron-2015-english-yify-47551'


# my @words = split /\Q$separator\E/, $name;
# my %word_count; # out of order
# foreach my $vid (@videos) {
#     foreach my $word (@words) {
#         $word_count{$vid}++ if $vid =~ m/\Q$word\E/i;
#     }
# }
# 
# my $best_match = (sort { $word_count{$a} <=> $word_count{$b} }
#                     keys %word_count)[-1];


# WORKS with mpv media player and option   sub-auto=fuzzy   in mpv.conf


# BUG
# /home/london/Downloads/Castle.Season.8/Ep-01.XY.mp4
# /home/london/Downloads/Castle.Season.8/Ep-02.XX.mp4
# /home/london/Downloads/Castle.Season.8/Ep-03.PhDead.mp4
# /home/london/Downloads/Castle.Season.8/Ep-04.What.Lies.Beneath.avi
# /home/london/Downloads/Castle.Season.8/Ep-05.The.Nose.mp4

# 
# Use of uninitialized value $s in regexp compilation at /home/london/.my_configurations/scripts/perl/subtitles/rename_subs.pl line 66.
# Use of uninitialized value $e in regexp compilation at /home/london/.my_configurations/scripts/perl/subtitles/rename_subs.pl line 66.
# Castle - 8x21 - Hell to Pay.HDTV.x264-KILLERS.en.srt
# -> Ep-22.Crossfire21.srt
# 
# Use of uninitialized value $s in regexp compilation at /home/london/.my_configurations/scripts/perl/subtitles/rename_subs.pl line 66.
# Use of uninitialized value $e in regexp compilation at /home/london/.my_configurations/scripts/perl/subtitles/rename_subs.pl line 66.
# Castle - 8x22 - Crossfire.HDTV.x264-LOL.en.srt
# -> Ep-22.Crossfire22.srt


# $ rename_subs
# Skins.S02E01.720p.x265-ZMNT_2.srt
# -> Skins.S02E01.720p.x265-ZMNT_3.srt
# 
# Skins.S02E02.720p.x265-ZMNT_2.srt
# -> Skins.S02E02.720p.x265-ZMNT_3.srt
# 
# Skins.S02E03.720p.x265-ZMNT_2.srt
# -> Skins.S02E03.720p.x265-ZMNT_3.srt
# 
# Skins - 2x04 - Michelle.720p HDTV.BiA.en.srt
# -> Skins.S02E04.720p.x265-ZMNT.srt
# 
# Skins - 2x04 - Michelle.aff.en.srt
# -> Skins.S02E04.720p.x265-ZMNT_2.srt
# 
# Skins - 2x05 - Chris.720p HDTV.BiA.en.srt
# -> Skins.S02E05.720p.x265-ZMNT.srt
# 
# Skins - 2x05 - Chris.ang.en.srt
# -> Skins.S02E05.720p.x265-ZMNT_2.srt
# 
# Skins - 2x06 - Tony.riv.en.srt
# -> Skins.S02E06.720p.x265-ZMNT.srt
# 
# Skins - 2x07 - Effy.riv.en.srt
# -> Skins.S02E07.720p.x265-ZMNT.srt
# 
# Skins - 2x08 - Jal.riv.en.srt
# -> Skins.S02E08.720p.x265-ZMNT.srt


use strict;
use warnings;
use File::Copy;

sub save_original_subs;

use v5.10;
local $,="\n"; 
local $\="\n"; 
# folder containing a copy of the original subtitle files
my $original_subs = "./.original_subs";
my ($s, $e);	# season, episode
my $vid_name;
my ($sub_name, $sub_ext);
my $sub_number;
my $new_sub_name;

my $video_file    = qr/ \. (?i) (mp4 | mkv | avi | m4v) $ /x;
my $subtitle_file = qr/ \. (?i) (srt | vtt | sub | idx) $ /x;

my $serie_episode_format = qr/ S (\d+) \.? E (\d+) /xi;


my @videos = map {chomp; $_} grep { /$video_file/ } qx( ls );
my @subs = map {chomp; $_} grep { /$subtitle_file/ } `ls`;

save_original_subs(@subs);

sub get_video_name {
	my $video = shift;
	my ($ext) = $video =~ $video_file;

	if (defined $ext) {
		return $video =~ s/\.$ext$//r;
	}
}

sub get_sub_ext {
	my $subtitle = shift;
	my ($ext) = $subtitle =~ $subtitle_file;
	my $name;

	if (defined $ext) {
		$name = $subtitle =~ s/\.$ext$//r;
	}
	return ($name, $ext);
}

# make a copy of the original subtitle files
sub save_original_subs {
    my @subs = @_;
    mkdir $original_subs;
    foreach my $sub (@subs) {
        if (! -e "$original_subs/$sub") {
#             copy($sub, "$original_subs/$sub");
        }
    }
}



foreach my $vid (@videos) {

	$sub_number = 1;

	($s, $e) = $vid =~ $serie_episode_format;

	if (not defined $s) {
		print "season number not found in :\n$vid\n";
		next;
	}
	elsif (not defined $e) {
		print "episode number not found in :\n$vid\n";
		next;
	}

	$s =~ s/^0+//;
	$e =~ s/^0+//;

	$vid_name = get_video_name($vid);

	foreach my $sub (@subs) {
		if ($sub =~ m/ S? 0? $s [.XE] 0? $e (?: \D | $ ) /xi) {

			($sub_name, $sub_ext) = get_sub_ext($sub);

			# don't rename correctly named subtitle file
			next if $sub_name =~ m/ ^ \Q$vid_name\E (?: _ \d+)? $ /x;

			# don't replace existing subtitle file
			do {
				$new_sub_name = $vid_name
							. ($sub_number > 1 ? "_$sub_number" : "")
							. "." . $sub_ext;
				$sub_number++;
			} while (-e $new_sub_name);

			print "$sub \n-> $new_sub_name\n";
# 			say "rename ", $sub, $new_sub_name;
			rename $sub, $new_sub_name;
		}
	}
}


__END__



