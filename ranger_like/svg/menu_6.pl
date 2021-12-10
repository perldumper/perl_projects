#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use Term::RawInput;
use Term::ReadKey;
use constant    RESET => "\e[0m";
use constant  REVERSE => "\e[7m";	# highlighting

# BUG WITH GREP
# grepc -rn 'copy_' | ~/perl/scripts/ranger_like/menu.pl


sub clean_exit {
	system "tput", "rmcup";
	ReadMode('normal');
	exit;
}

$SIG{INT} = sub { clean_exit() };

my $debug = defined $ARGV[0] ? ( $ARGV[0] =~ /^-{0,2}debug$/ ? 1 : 0 ) : 0;

local $,="\n";
local $\="\n";
my $start_esc_seq = "\x{1B}\x{5B}";				# \e[
my $_0m           = "\x{30}\x{6D}";				# 0m
my $reset_end     = "\x{30}\x{6D}";				# 0m
my $reverse       = "\x{1B}\x{5B}\x{37}\x{6D}";	# \e[7m
my $reset         = "\x{1B}\x{5B}\x{30}\x{6D}";	# \e[0m

# my @lines = (map { chomp; s/\x{1B}\x{5B}\x{4B}//gr 
#                        =~ s/\x{1B}\x{5B}//gr
#                        =~ s/\t/ " " x 8 /erg } <STDIN>);	

# my @lines = (map { chomp;
#                           s/\x{1B}\x{5B}\x{4B}//gr 
#                        =~ s/\x{1B}\x{5B}\x{6D}//gr
#                        =~ s/\t/ " " x 8 /erg
# } <STDIN>);	

my @lines = (map { chomp; s/\t/ " " x 8 /erg } <STDIN>);	

# print @lines; exit;

# because REVERSE on tabs doesn't make highlighting
# remove ^[[K at the end, because if it has not the normal form of escape sequences and is not remove,
# which makes the length wrong

my @length = map { length
					      s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m //rgx
                       =~ s/\x{1B}\x{5B}\x{4B}//gr 
                       =~ s/\x{1B}\x{5B}\x{6D}//gr

} @lines;

if (! -t STDIN) {	# if STDIN is not tty == if there is something to read from a pipe via STDIN
	close STDIN;
	open STDIN, "</dev/tty";
}

# ESC_SEQ    string    RESET   -->  REVERSE ESC_SEQ    string      RESET  REVERSE

my @reverse_lines = map {    s#\Q$start_esc_seq\E (?! $_0m ) #${reverse}${start_esc_seq}#rgx
                          =~ s#\Q$start_esc_seq\E     $_0m   #${start_esc_seq}${_0m}${reverse}#rgx
                          =~ s# $ #${reset}#rx
                          =~ s#^#${reset}#r  } @lines;

#                           =~ s#^#${reset}#r =~ s/\x{1B}\x{5B}//rg  } @lines;

my $pos=0;						# line currently highlighted / selected
my ($input,$key) = ("","");
my ($width, $heigth);
my $columns_to_eol;

# system "tput", "smcup";
system "tput", "smcup" unless $debug;

while ($key ne "ENTER") {
# 	system "clear";
	system "clear" unless $debug;
	($width, $heigth) = GetTerminalSize();

	for (my $i=0; $i < @lines; $i++){
		if ($i == $pos) {
			$columns_to_eol = $width - $length[$i];
			print $reverse_lines[$i] . ($columns_to_eol > 0 ? REVERSE . (" " x $columns_to_eol) . RESET : "") unless $debug;
			# $columns_to_eol is < 0 if the line is wider than the screen
			print $lines[$i] if $debug;
		}
		else {
			print $lines[$i]
		}
	}
	exit if $debug;
	($input,$key) = rawInput("",1);
	if (lc $input eq "q") {
		clean_exit()
	}

	if ($key eq "UPARROW") {
		$pos = $pos > 1 ? $pos-1 : 0
	}
	elsif ($key eq "DOWNARROW") {
		$pos = ($pos < $#lines ? $pos+1 : $#lines)
	}
	elsif ($key eq "PAGEUP") {
	}
	elsif ($key eq "PAGEDOWN") {
	}
	elsif ($key eq "HOME") {
	}
	elsif ($key eq "END") {
	}
}


system "tput", "rmcup";

# print "\n" x 4;

# print $lines[$pos];
# print $lines[$pos] =~ s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m //rgx;

# exit;
my ($file, $line) = $lines[$pos]
                  =~ s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m //rgx
                  =~ s/\x{1B}\x{5B}\x{4B}//gr 
                  =~ s/\x{1B}\x{5B}\x{6D}//gr
                  =~ m/^(.*?):(\d+):/;

# regex doesn't work for files whose name contain this pattern  ':\d+:/'

# print $file;
# print $line;

system "vim", $file, "+$line";

__END__


perl -MTerm::ReadKey -My -le '($width,$heigth)=GetTerminalSize(); $,="\n"; print $width; print REVERSE . " "x$width.RESET'

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


