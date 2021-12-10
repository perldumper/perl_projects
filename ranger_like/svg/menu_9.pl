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
no warnings "once";		# *lines_text = *lines
use autodie;
use Term::RawInput;
use Term::ReadKey;
use constant    RESET => "\e[0m";
use constant  REVERSE => "\e[7m";	# highlighting

# my $debug = defined $ARGV[0] ? ( $ARGV[0] =~ /^-{0,2}debug$/ ? 1 : 0 ) : 0;
my $debug = 0;
# my $no_flicker = 0;	# if true, avoid flash of main terminal screen after selecting a line in the menu and before vim opens
						# to make it easy on the eyes
my $no_flicker = 1;

while (defined(my $arg = shift @ARGV)) {
	if ($arg =~ m/^-{0,2}debug$/) {
		$debug = 1;
	}
	elsif ($arg =~ m/^-{0,2}no-flicker$/) {
		$no_flicker = 1;
	}
}

sub clean_exit {
	if ($no_flicker) {
		system "clear";
	}
	else {
		system "tput", "rmcup";
	}
	ReadMode('normal');
	exit;
}

$SIG{INT} = sub { clean_exit() };

local $,="\n";
local $\="\n";
# local $|=1;
# $|=1;
my $start_esc_seq = "\x{1B}\x{5B}";				# \e[
my $_0m           = "\x{30}\x{6D}";				# 0m	# the ending part of the reset escape sequence
my $reverse       = "\x{1B}\x{5B}\x{37}\x{6D}";	# \e[7m
my $reset         = "\x{1B}\x{5B}\x{30}\x{6D}";	# \e[0m

sub remove_escape_sequences {
	return $_[0]
		=~ s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m //rgx
		=~ s/\x{1B}\x{5B}\x{4B}//gr		# ^[[K
        =~ s/\x{1B}\x{5B}\x{6D}//gr		# ^[[m  (visible with cat -e)  grep(1) resest

	# remove ^[[K at the end, because if it has not the normal form of escape sequences and is not remove,
	# which makes the length wrong
}

my @lines = (map { chomp; s/\t/ " " x 8 /erg } <STDIN>);	# because REVERSE on tabs doesn't make highlighting

unless (remove_escape_sequences($lines[0]) =~ /^.*?:\d+:/) {
	print "require ^filename:line_number:";
	exit;
}

if (! -t STDIN) {	# if STDIN is not tty == if there is something to read from a pipe via STDIN
	close STDIN;
	open STDIN, "<", "/dev/tty";
}

# ESC_SEQ    string    RESET   -->  REVERSE ESC_SEQ    string      RESET  REVERSE


my @length;
my @reverse_lines;
# my $colored_input = (grep { /\Q${reset}\E | \x{1B}\x{5B}\x{6D} /x } @lines) ? 1 : 0 ;
my $colored_input = $lines[0] =~ /\Q${reset}\E | \x{1B}\x{5B}\x{6D} /x ? 1 : 0 ;
my @lines_text;

# print "COLORED INPUT $colored_input";
# exit;

if ($colored_input) {
	@reverse_lines = map {    s#\Q$start_esc_seq\E (?! $_0m ) #${reverse}${start_esc_seq}#rgx
						   =~ s#\Q$start_esc_seq\E     $_0m   #${start_esc_seq}${_0m}${reverse}#rgx
						   =~ s# $ #${reset}#rx
												 } @lines;
# 						   =~ s# ^ #${reset}#rx  } @lines;

	@lines_text = map {       s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m //rgx
            	           =~ s/\x{1B}\x{5B}\x{4B}//gr		# ^[[K
                	       =~ s/\x{1B}\x{5B}\x{6D}//gr		# ^[[m  (with cat -e)
                    	
	                  } @lines;
	@length = map { length } @lines_text;
}
else {
	@reverse_lines = map { s# ^ #${reverse}#rx 
                        =~ s# $ #${reset}#rx } @lines;

# 	@lines_text = map { s/^\Q${reverse}\E//r =~ s/\Q${reset}\E$//r } @lines;
	@lines_text = @lines;
# 	*lines_text = *lines;
# 	*lines_text = \*lines;
	@length = map { length } @lines;
}

# exit unless $lines_text[0] =~ /^.*?:\d+:/;

# print for @lines;
# print for @reverse_lines;
# print "COLORED INPUT $colored_input";
# exit;

my $pos=0;						# line currently highlighted / selected
my ($input,$key);
my ($width, $heigth);
my $columns_to_eol;
my ($file, $line);
my $frame;
my ($frame_start, $frame_end) = (0);
my $input_buffer = "";
my $cursor_pos = 1;
my $mode = 1;	# 1 --> : (default)  2 --> / (regex mode)

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
# 	local $\ = ""; print "\e[15;5H"; local $\ = "\n";

# 	for (my $i=0; $i < @lines; $i++){
# 	for (my $i=0; $i < $frame; $i++){
# 	for (my $i= $frame_start; $i < $frame_start + $frame ; $i++){
	for (my $i= $frame_start; $i < $frame_start + $frame - 1; $i++){

		if ($i == $pos) {
			$columns_to_eol = $width - $length[$i];
# 			print $reverse_lines[$i] . ($columns_to_eol > 0 ? REVERSE . (" " x $columns_to_eol) . RESET : "");
			if (length $input_buffer > 0) {
# 			if ($mode == 2) {
				print $reverse_lines[$i] . ($columns_to_eol > 0 ? REVERSE . (" " x $columns_to_eol) . RESET : "")
					if $lines_text[$i] =~ /$input_buffer/;
			}
			else {
				print $reverse_lines[$i] . ($columns_to_eol > 0 ? REVERSE . (" " x $columns_to_eol) . RESET : "");
			}
# 			print $reverse_lines[$i] . ($columns_to_eol > 0 ? REVERSE . (" " x $columns_to_eol) . RESET : "") unless $debug;
			# $columns_to_eol is < 0 if the line is wider than the screen
# 			print $lines[$i] if $debug;
		}
		else {
# 			print $lines[$i]
# 			chomp $lines[$i];
# 			print "\"$lines[$i]\"";

			if (length $input_buffer > 0) {
				print $lines[$i] if $lines_text[$i] =~ /$input_buffer/;
			}
			else {
				print $lines[$i];
			}
		}
	}
# 	print "INPUT \"$input\"";
# 	print "KEY \"$key\"";
# 	local $\ = ""; print "\e[15;5H"; local $\ = "\n";

# 	local $|=1;
	print $mode == 1 ? ":" : "/$input_buffer";
# 	print "/$input_buffer";
# 	local $\ = ""; print "\e[15;5H"; local $\ = "\n";

	local $\="";
# 	print "\e[2A";
	print "\e[A";
# 	print "\e[${cursor_pos}C";
# 	print "/$input_buffer";
# 	print " " x ${cursor_pos};

# 	print "\e[A";
# 	print "\e[B";
# 	print "\e[C";
# 	print "\e[D";
# 	print "\e[15;5H";

# 	print "\e[2A";
# 	print "\e[2B";
# 	print "\e[2C";
# 	print "\e[2D";
	local $\="\n";

	exit if $debug;

# 	print "\e[15;5H";
	($input,$key) = rawInput("",1);
# 	($input,$key) = rawInput("",0);
	if ($mode == 1) {
		if (lc $input eq "q") {
			clean_exit()
		}
		elsif ($input eq "/") {
			$mode = 2;		# regex mode
			next;
		}
	}


# 	local $\ = ""; print "\e[15;5H"; local $\ = "\n";
	# take into account lines that are wider than the screen and takes more than  1 terminal heigth

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

		if ($pos > $frame_start + $frame - 1) {
			$frame_start = $frame_start + 1;
		}
		else {
# 			$frame_start = $#lines - $frame + 1;
		}
	}
	elsif ($key eq "PAGEUP") {
		if ($frame_start - $frame >= 0) {
			$frame_start = $frame_start - $frame;
			$pos = $frame_start + $frame - 1;
		}
		else {
			$frame_start = 0;
			$pos = $frame - 1;
		}
	}
	elsif ($key eq "PAGEDOWN") {
		if ($frame_start + $frame < $#lines - $frame) {
			$frame_start = $frame_start + $frame;
			$pos = $frame_start;
		}
		else {
			$frame_start = $#lines - $frame;
			$pos = $frame_start;
		}
	}
	elsif ($key eq "HOME") {
		$frame_start = 0;
		if ($pos > $frame - 1) {
			$pos = 0;
		}
	}
	elsif ($key eq "END") {
		$frame_start = $#lines - $frame + 1;
		if ($pos < $#lines - $frame + 1) {
			$pos = $#lines;
		}
	}
	elsif ($key eq "BACKSPACE") {
		if ($mode == 2) {
			if (length $input_buffer >= 1) {
				chop $input_buffer;
			}
			else {
				$mode = 1;
			}
		}
	}
	elsif ($key eq "ENTER") {

# 		($file, $line) = remove_escape_sequences($lines[$pos]) =~ m/^(.*?):(\d+):/;
		($file, $line) = $lines_text[$pos] =~ m/^(.*?):(\d+):/;

# 		system "tput", "rmcup"; print $lines_text[$pos]; exit;

		# because there is only one alternate screen, and vim, internally, himself, go to the alternate screen,
		# and then returns to the normal screen. And somehow, this erase the original screen that we saved, so we need to
		# to the normal screen, and then return to alternate screen after exiting vim
 		system "tput", "rmcup" unless $no_flicker;
		system "vim", $file, "+$line";
		system "tput", "smcup";
	}
	else {
		if ($mode == 2) {
			$input_buffer .= $input;
			$cursor_pos = 1 + length $input_buffer;
		}
	}
}

