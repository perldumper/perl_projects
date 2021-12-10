#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use Convert::Binary::C;
use dd;
use Tie::IxHash;

my $c = Convert::Binary::C->new(
#     Alignment => 4,
    ByteOrder => "BigEndian",
#     ByteOrder => "LittleEndian",
);

$c->parse(<<'END');

struct header {
    char id[3];
    char version[2];
    char flags;
    int size;
};

END
;

@ARGV // die "no files given";

# my $file = "./colocation.mp3";
# my $file = shift // die "no file specified";

if ($c->sizeof("header") != 10 ) {
    die "wrong alignment"
}

my $fh;

# foreach my $file (@ARGV) {
foreach my $file ( grep { -e $_ && -f $_ } @ARGV) {

    say "";
    say $file;
    unless (-e $file && -f $file) {
        say "not a file: \"$file\"";
        next;
    }

my $bytes;
my %ID3_tag;
tie %ID3_tag, "Tie::IxHash";

# dd $c;
# say $c->sizeof("header");


open $fh, "<:raw", $file;
read $fh, $bytes, 10;

my @bytes = unpack(" (a)3 ", $bytes);
# say join " ", @bytes;
# say $bytes[0];
# next;

unless ($bytes[0] eq "I" && $bytes[1] eq "D" && $bytes[2] eq "3") {

    say "no ID3 tag detected";
    next;
}

my $header = $c->unpack('header', $bytes);



# dd $header;
# say map { chr } $header->{id}->@*;
# say $header->{version}->@*;
# say $header->{flags};
# say $header->{size};

# dd $c->struct("header");

# foreach (0 .. $c->sizeof("header")-1 ) {
#     say $c->member("header", $_);
# }

# say $c->def("header") ? 1 : 0;
# say $c->def("struct header") ? 1 : 0;

if (join("", map {chr} $header->{id}->@*) ne "ID3" ) {
#     die "no ID3 tag detected in \"$file\"";
    warn "no ID3 tag detected in \"$file\"";
}

$ID3_tag{version} = "Version ID3v2."
    . $header->{version}->[0] . "." . $header->{version}->[1];


say $ID3_tag{version};


$ID3_tag{flags} = {
    unsynchronization       => $header->{flags} >> 7 & 0x01,
    extended_header         => $header->{flags} >> 6 & 0x01,
    experimental_indicator  => $header->{flags} >> 5 & 0x01,
    footer                  => $header->{flags} >> 4 & 0x01,
};

# for (keys $ID3_tag{flags}->%*) {
#     say "$_\t$ID3_tag{flags}->{$_}"
# }

for my $i (3 .. 0) {
    if ($header->{flags} >> $i & 0x01) {
        die "flag $i should be 0"
    }
}

if ($ID3_tag{flags}->{extended_header}) {

#     read $fh, $bytes, 10;
#     my $extended_header = $c->unpack('extended_header', $bytes);

    say "extended_header";
    exit 1;
#     last;
}


}
continue {

    close $fh;
}


__END__

