#!/usr/bin/perl

# EXAMPLES :
# ack --color 'pattern' | ./menu.pl
# grep -rn --color=always 'pattern' | ./menu.pl
# grep -Hn --color=always 'pattern' * | ./menu.pl

# this script requires, using grep(1) :
# - forcing color ==> --color=always      (color is optional)
# - filename      ==> -H    (or implied with -r / -recursive)
# - line number   ==> -n

# this script requires, using ack(1) :
# - forcing color ==> --color             (color is optional)
# - filename      ==> (default)
# - line number   ==> (default)

# solution to type less :
# alias grepc='grep --color=always'
# alias ackc='ack --color'
# alias less='less -R'

# to exit vim rapidly, put this in the vimrc file :
# noremap <F4> :q<CR>

# ----------------------------------------------------------------

# TO CORRECT
# grep -r 'copy_' | ~/perl/scripts/ranger_like/menu.pl

# /usr/bin/vendor_perl/ack 'copy_' | ~/perl/scripts/ranger_like/menu.pl

use strict;
use warnings;
use autodie;
use Term::RawInput;
use Term::ReadKey;
use constant    RESET => "\e[0m";
use constant  REVERSE => "\e[7m";	# highlighting

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
my $_0m           = "\x{30}\x{6D}";				# 0m	# the ending part of the reset escape sequence
my $reverse       = "\x{1B}\x{5B}\x{37}\x{6D}";	# \e[7m
my $reset         = "\x{1B}\x{5B}\x{30}\x{6D}";	# \e[0m

my @lines = (map { chomp; s/\t/ " " x 8 /erg } <STDIN>);	# because REVERSE on tabs doesn't make highlighting


# remove ^[[K at the end, because if it has not the normal form of escape sequences and is not remove,
# which makes the length wrong

my @length = map { length
					      s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m //rgx
                       =~ s/\x{1B}\x{5B}\x{4B}//gr 		# ^[[K
                       =~ s/\x{1B}\x{5B}\x{6D}//gr		# ^[[m  (visible with cat -e)

                 } @lines;

if (! -t STDIN) {	# if STDIN is not tty == if there is something to read from a pipe via STDIN
	close STDIN;
	open STDIN, "<", "/dev/tty";
}

# ESC_SEQ    string    RESET   -->  REVERSE ESC_SEQ    string      RESET  REVERSE


my @reverse_lines;
my $colored_input = (grep { /\Q${reset}\E/ } @lines) ? 1 : 0 ;

if ($colored_input) {
	@reverse_lines = map {    s#\Q$start_esc_seq\E (?! $_0m ) #${reverse}${start_esc_seq}#rgx
						   =~ s#\Q$start_esc_seq\E     $_0m   #${start_esc_seq}${_0m}${reverse}#rgx
						   =~ s# $ #${reset}#rx
												 } @lines;
# 						   =~ s# ^ #${reset}#rx  } @lines;
}
else {
	@reverse_lines = map { s# ^ #${reverse}#rx 
                        =~ s# $ #${reset}#rx } @lines;
}




my $pos=0;						# line currently highlighted / selected
my ($input,$key);
my ($width, $heigth);
my $columns_to_eol;
my ($file, $line);
my $frame;
my ($frame_start, $frame_end) = (0);

system "tput", "smcup";

while (1) {
	system "clear";
	($width, $heigth) = GetTerminalSize();
# 	$frame = $heigth < ($#lines + 1) ? $heigth : ($#lines + 1);
	$frame = $heigth < ($#lines + 1) ? $heigth - 1 : ($#lines + 1);
# 	print $heigth;
# 	exit;
# 	print $minimum;
# 	exit;

# 	for (my $i=0; $i < @lines; $i++){
# 	for (my $i=0; $i < $frame; $i++){
	for (my $i= $frame_start; $i < $frame_start + $frame; $i++){

		if ($i == $pos) {
			$columns_to_eol = $width - $length[$i];
			print $reverse_lines[$i] . ($columns_to_eol > 0 ? REVERSE . (" " x $columns_to_eol) . RESET : "");
# 			print $reverse_lines[$i] . ($columns_to_eol > 0 ? REVERSE . (" " x $columns_to_eol) . RESET : "") unless $debug;
			# $columns_to_eol is < 0 if the line is wider than the screen
# 			print $lines[$i] if $debug;
		}
		else {
			print $lines[$i]
# 			chomp $lines[$i];
# 			print "\"$lines[$i]\"";
		}
	}
	exit if $debug;
	($input,$key) = rawInput("",1);
	if (lc $input eq "q") {
		clean_exit()
	}

	if ($key eq "UPARROW") {
		$pos = $pos > 1 ? $pos - 1 : 0;

# 		$frame_start = $frame_start > 1 ? $frame_start - 1 : 0 ;
		if ($pos < $frame_start) {
			$frame_start = $frame_start - 1;
		}
		else {
# 			$frame_start = $#lines - $frame + 1;
		}
	}
	elsif ($key eq "DOWNARROW") {
		$pos = ($pos < $#lines ? $pos + 1 : $#lines);

# 		$frame_start = $frame_start + $frame < $#lines ? $frame_start + 1 : $#lines - $frame + 1 ;
# 		if ($frame_start + $frame < $#lines) {
# 			$frame_start = $frame_start + 1;
# 		}
# 		else {
# 			$frame_start = $#lines - $frame + 1;
# 		}

		if ($pos > $frame_start + $frame - 1) {
			$frame_start = $frame_start + 1;
		}
		else {
# 			$frame_start = $#lines - $frame + 1;
		}


	}
	elsif ($key eq "PAGEUP") {
	}
		# update frame_start and frame_end
	elsif ($key eq "PAGEDOWN") {
		# update frame_start and frame_end
	}
	elsif ($key eq "HOME") {
		# update frame_start and frame_end
	}
	elsif ($key eq "END") {
		# update frame_start and frame_end
	}
	elsif ($key eq "ENTER") {

		if ($colored_input) {
			($file, $line) = $lines[$pos]
        	               =~ s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m //rgx
            	           =~ s/\x{1B}\x{5B}\x{4B}//gr		# ^[[K
                	       =~ s/\x{1B}\x{5B}\x{6D}//gr		# ^[[m  (with cat -e)
                    	   =~ m/^(.*?):(\d+):/;
		}
		else {
			($file, $line) = $lines[$pos]
                           =~ s/^\Q${reverse}\E//r =~ s/\Q${reset}\E$//r
                    	   =~ m/^(.*?):(\d+):/;
		}

		# because there is only one alternate screen, and vim, internally, himself, go to the alternate screen,
		# and then returns to the normal screen. And somehow, this erase the original screen that we saved, so we need to
		# to the normal screen, and then return to alternate screen after exiting vim
		system "tput", "rmcup";
		system "vim", $file, "+$line";
		system "tput", "smcup";
	}
}

__END__


# print "\n" x 4;

# print $lines[$pos];
# print $lines[$pos] =~ s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m //rgx;

# exit;
my ($file, $line) = $lines[$pos]
                  =~ s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m //rgx
                  =~ s/\x{1B}\x{5B}\x{4B}//gr		# ^[[K
                  =~ s/\x{1B}\x{5B}\x{6D}//gr		# ^[[m  (with cat -e)
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


