#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use File::Basename;

exit unless @ARGV;

# sub notify {
#     system "notify-send", join "|", @_;
# }

sub position {
    my ($aref, $string) = @_;
    for (my $i=0; $i <= $aref->$#*; $i++) {
        return $i if $aref->[$i] eq $string;
        1;
    }
    return undef;
}

my $dir = dirname $ARGV[0];

# add sort ?
my @files = map { s|^\.|$dir|r }
            grep { ! m/ \. (?: pdf|html|mkv|mp4|webm|mp3|weba|m4a ) $ /x }
            map { chomp; $_ }
            qx{ find \"$dir\" -maxdepth 1 -type f };
;


if (@ARGV == 1) {
#     notify("IF");

    my $pos = position(\@files, $ARGV[0]) + 1;

#     notify("POS $pos");
#     notify(@files);
#     notify( grep { -e $_ } @files);

    system "sxiv", "-n", $pos, @files;
#     system "sxiv", @files;
#     system "sxiv", $ARGV[0];
}
else {
#     notify("ELSE");
    system "sxiv", @ARGV;
}




__END__

Exec=find -maxdepth 1 -type f \! \( -iname "*mkv" -o -iname "*mp4" -o -iname "webm" -o -iname "*pdf" -o -iname "*mp3" -o -iname "weba" -o -iname "*m4a"  \)  \| sxiv -


