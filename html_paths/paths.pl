#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use lib "./";
# use lib "/home/london/perl/scripts/parsing_html/";  # will have to change it to the correct folder of paths.pm
use paths;
use dd;

my $p = myparser->new(
#     api_version => 3,
#     api_version => 2,
#     api_version => 1,
);

$p->{all} = 0;

if (@ARGV && $ARGV[0] =~ /^-{1,2}all$/) {
    $p->{all} = 1;
    shift;
}

# dd $p;
# say "true" if $p->isa("HTML::Parser");
# say "true" if $p->can("parse");
# say "true" if $p->can("parse_file");
# exit;

# $p->parse_file(shift);
# exit;

if (@ARGV) {
	if (-e $ARGV[0]) {
#         say STDERR "ARGV FILE";
        $p->parse_file(shift);
    }
	else {
#         say STDERR "ARGV STRING";
        $p->parse(shift);
    }
}
elsif (not -t STDIN) {
#     say STDERR "STDIN";
    local $/;
    $p->parse(<STDIN>);
}



__END__

