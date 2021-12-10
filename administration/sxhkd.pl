#!/usr/bin/perl

use strict;
use warnings;
use feature 'signatures';
no warnings "experimental::signatures";
use List::MoreUtils qw(slide);
use List::Util qw(unpairs pairgrep pairmap);

# local $,="";
# local $\="\n";

my $sxhkdrc = "$ENV{HOME}/.config/sxhkd/sxhkdrc";

if (! -t STDOUT) {
    local @ARGV = $sxhkdrc;
    print <ARGV>;
    exit;
}

my %keys = (
    "'" => 'apostrophe',
    ';' => 'semicolon',
    ',' => 'comma',
    '.' => 'period',
    '/' => 'slash',
    '`' => 'grave',
    '[' => 'bracketleft',
    ']' => 'bracketright',
);


my @lines;
my $pat;

if (not @ARGV) {
#     #vim ~/.config/sxhkd/sxhkdrc && pidof sxhkd | xargs kill -SIGUSR1
#     vim ~/.config/sxhkd/sxhkdrc && pidof sxhkd | kill -SIGUSR1 $(cat /dev/stdin)    # CURRENT
#     #vim ~/.config/sxhkd/sxhkdrc && (sxhkd -c ~/.config/sxhkd/sxhkdrc &> /dev/null &)

    system "vim $sxhkdrc && pidof sxhkd | xargs kill -SIGUSR1";
}
else {
    @lines = do { local @ARGV = $sxhkdrc; grep {!/^\s*#/} <ARGV> };
    if ($ARGV[0] eq "--") {
        shift;
        $pat = join " ", @ARGV;
        $pat =~ s/ \Q$_\E /$keys{$_}/gx for keys %keys;
    }
    else {
        $pat = join " ", @ARGV;
        $pat =~ s/ \Q$_\E /$keys{$_}/gx for keys %keys;
        $pat = quotemeta $pat;
    }

    print grep {/$pat/i}
          pairmap { $a . $b . "\n" }
          pairgrep { $a =~ /^\S/ and $b =~ /^\s+\S/ }
          unpairs
          slide {[$a, $b]} @lines;
}



__END__

function sx() {

	if [ -z "$1"  ] ; then
		#vim ~/.config/sxhkd/sxhkdrc && pidof sxhkd | xargs kill -SIGUSR1
		vim ~/.config/sxhkd/sxhkdrc && pidof sxhkd | kill -SIGUSR1 $(cat /dev/stdin)
		#vim ~/.config/sxhkd/sxhkdrc && (sxhkd -c ~/.config/sxhkd/sxhkdrc &> /dev/null &)

	elif [ $# -ge 1 ] ; then
		perl -MList::MoreUtils=slide -MList::Util=unpairs,pairgrep,pairmap -e '
			{ local @ARGV=("$ENV{HOME}/.config/sxhkd/sxhkdrc");
			@lines=grep {!/^\s*#/} <ARGV> }
			if ($ARGV[0] eq "--") { shift; $pat = join " ", @ARGV }
			else                  {$pat=quotemeta join " ", @ARGV }
			print grep {/$pat/i} pairmap { $a . $b . "\n" }
				pairgrep { $a =~ /^\S/ and $b =~ /^\s+\S/ } unpairs slide {[$a, $b]} @lines
			' -- "$@"
	fi
}



