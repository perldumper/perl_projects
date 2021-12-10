#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use Term::RawInput;
use y;;;;	# color constants

local $,="\n";
local $\="\n";

my @lines = (map { chomp; $_ } <STDIN>)[0..20];
if (! -t STDIN) {	# if STDIN is not tty == if there is something to read from a pipe via STDIN
	close STDIN;
	open STDIN, "</dev/tty";
}

# my @lines = map { chomp; $_ } (`ls`)[0..10];
# my @lines = map { chomp; $_ } (`ls`)[0..50];
# my @lines = map { chomp; $_ } (`ls`);
my $pos=0;
my ($input,$key) = ("","");
my $prompt;

system "tput", "smcup";

while ($key ne "ENTER") {
	system "clear";
	for (my $i=0;$i<@lines;$i++){
		if ($i == $pos) {
			print REVERSE . GREEN . $lines[$i] . RESET
		}
		else {
			print GREEN . $lines[$i] . RESET
		}
	}
	($input,$key) = rawInput($prompt,0);
	if ($key eq "UPARROW") {
		$pos = $pos > 1 ? $pos-1 : 0
	}
	elsif ($key eq "DOWNARROW") {
		$pos = ($pos < $#lines ? $pos+1 : $#lines)
	}
}


system "tput", "rmcup";


__END__

perl -e 'system "tput", "smcup"; print `ls`; sleep 2; system "clear"; system "tput", "rmcup"'

perl -MTerm::RawInput -le '$key=""; while ($key ne "ENTER") { ($input,$key)=rawInput("",0); print $key }'

left		LEFTARROW
right		RIGHTARROW
up			UPARROW
down		DOWNARROW

return		ENTER

home		HOME
end			END
pageup		PAGEUP
pagedown	PAGEDOWN

F1
F2
F3
F4
F5
F6
F7
F8
F9
F10
F11
F12


