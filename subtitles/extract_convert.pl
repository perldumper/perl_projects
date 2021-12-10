#!/usr/bin/perl

# only works for .ass subtitles ?

use strict;
use warnings;
use Term::ANSIColor qw(:constants);
use Capture::Tiny qw(capture_stdout capture_stderr);

exit unless @ARGV;

sub read_file {
    my $file = shift;
    open my $FH, "<", $file;
    return <$FH>;
}

sub write_file {
    local $\ = "";
    my $file = shift;
    open my $FH, ">", $file;
    print $FH @_;
    close $FH;
}

sub menu {
    my $idx = 0;
    foreach (@_) {
        printf " %s%-4s%s%s\n", YELLOW, $idx++, RESET, $_;
    }
    printf "\n%sWhich subtitle ?%s ", GREEN, RESET;
    my $choice = <STDIN>;
}

sub choose_subtitle {
    my $video = shift;
    my @ffprobe = map { split /\n/ } capture_stderr { system "ffprobe", $video };
    my @subs = grep {/Stream\s+#.*?Subtitle/} @ffprobe;
    my $choice;
    if (@subs == 0) {
        die "no subtitles available\n";
    }
    elsif (@subs == 1) {
        $choice = 0;
    }
    else {
        $choice = menu(@subs);
    }
    my ($track) = $subs[$choice] =~ m/^\s+Stream\s+#(\d+:\d+).*?Subtitle:/;
    return $track;
}

sub extract_subtitles {
    my ($video, $subtitle_ass, $track) = @_;
    system "ffmpeg -y -i \"$video\" -map $track \"$subtitle_ass\" 2> /dev/null";
}

sub ass_to_vtt {
    my ($start,$end,$text);
    my @vtt;
    foreach (@_) {
        chomp;
        if (/^Dialogue:.*?,(?<start>.*?),(?<end>.*?),(?:.*?,){6}(?<text>.*)/) {

            $start = "0" . $+{start} . "0";	# 2 digits for hours, 3 digits for milliseconds
            $end   = "0" . $+{end}   . "0";
            $text  = $+{text};
            push @vtt, "$start --> $end\n";
            # put real new lines and transform italic marks into italic tags
            push @vtt, $3 =~ s/\\N/\n/gr =~ s/\{\\i\d\}(.*?)\{\\i\d\}/<i>$1<\/i>/rg, "\n\n"
        }
    }
    return @vtt;
}

sub dos2unix {
    my $file = shift;
    my $stdout = capture_stdout {system "dos2unix --info \"$file\""};
    $stdout =~ s/^\s+//;
    # lb = line break, BOM = byte order mark
    my ($DOS_lb, $Unix_lb, $Mac_lb, $BOM) = split /\s+/, $stdout;

    unless ($DOS_lb == 0 && $Mac_lb == 0 && $BOM eq "no_bom") {
        system "dos2unix \"$file\" 2> /dev/null";
    }
    if ($? != 0) {
        die "error with dos2unix\n";
    }
}

my $subtitle_track;
for (1) {
    if (@ARGV) {
        if ($ARGV[0] =~ /^--sub(?:=(\S+))?/) {
            shift;
            $subtitle_track = $1 // shift;
            unless ($subtitle_track =~ /\A\d+:\d+\z/) {
                die "subtitle track should match /^\\d+:\\d+\$/\n";
            }
        }
    }
}

# my $video = shift;
for my $video (@ARGV) {
    print "Extracting subtitles from \"$video\"\n";
    my ($basename) = $video =~ m/^(.*)\.[^.]+$/;
    my $subtitle_ass = "./.$basename.ass";
    my $subtitle_vtt = "./$basename.vtt";

    $subtitle_track //= choose_subtitle($video);

    extract_subtitles($video, $subtitle_ass, $subtitle_track);

    # convert ass into vtt
    my @vtt = ass_to_vtt(read_file($subtitle_ass));

    if (-e $subtitle_vtt && ! -z $subtitle_vtt) {
#         die "\"$subtitle_vtt\" already exsits!\n";
        print STDERR "\"$subtitle_vtt\" already exsits!\n\n";
        next;
    }

    my @vtt_subtitle = ("WEBVTT\nKind: captions\nLanguage: en\n\n", @vtt);

    write_file($subtitle_vtt, @vtt_subtitle);
    dos2unix($subtitle_vtt);

    unlink $subtitle_ass;
    print "--> \"$subtitle_vtt\"\n\n";
}

