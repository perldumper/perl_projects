#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use Term::RawInput;
use Term::ReadKey;
use y;;;;	# color constants

# use terminal width and heigth ?
# put spaces at the end of lines so that the white of a line selected goes to the right of the screen


# ls --color=always | ~/perl/scripts/ranger_like/menu.pl

# london@archlinux:~/perl/scripts/equations/equations
# $ ack 'copy_' | ~/perl/scripts/ranger_like/menu.pl

# ack 'copy_' | perl -pe 's/^.*?://' | ~/perl/scripts/ranger_like/menu.pl
# ack 'copy_' | perl -pe 's/^(?:.*?:){2}//' | ~/perl/scripts/ranger_like/menu.pl

# have to remove the escape sequence for RESET ?
# no because it will remove color boundaries

# ls --color=always | head | perl -pe 's/\x{1b}\x{5b}(?!\x{30}\x{6d})/\x{1b}\x{5b}\x{37}\x{6d}\x{1b}\x{5b}/g'

# perl -My -le 'print REVERSE . "text  text" . RESET'

local $,="\n";
local $\="\n";

my $start_esc_seq = "\x{1b}\x{5b}";
my $_0m           = "\x{30}\x{6d}";
my $reset_end     = "\x{30}\x{6d}";
my $reverse       = "\x{1b}\x{5b}\x{37}\x{6d}";
my $reset         = $start_esc_seq . $_0m;

# my @lines = map { chomp; $_ } <STDIN>;
my @lines = (map { chomp; $_ } <STDIN>)[0..20];

@lines = map { s/\t/        /rg } @lines;		# because REVERSE tabs is black and REVERSE space is white

my @length = map { length s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m? //rgx } @lines;

# print "$length[$_]\t$lines[$_]" for 0 .. $#lines;
# exit;

if (! -t STDIN) {	# if STDIN is not tty == if there is something to read from a pipe via STDIN
	close STDIN;
	open STDIN, "</dev/tty";
}

# s/  START_ESCPAE_SEQUENCE  / REVERSE START_ESCAPE_SEQUENCE  /gr
# my @reverse_lines = map { s/\x{1b}\x{5b}/\x{1b}\x{5b}\x{37}\x{6d}\x{1b}\x{5b}/gr } @lines;

# s/  START_ESCPAE_SEQUENCE (?! 0m (esapce sequence that isn't RESET) )  / REVERSE START_ESCAPE_SEQUENCE  /gr
# my @reverse_lines = map { s/\x{1b}\x{5b}(?!\x{30}\x{6d})/\x{1b}\x{5b}\x{37}\x{6d}\x{1b}\x{5b}/gr } @lines;


# my @reverse_lines = map { s/\x{1b}\x{5b}(?!\x{30}\x{6d})/\x{1b}\x{5b}\x{37}\x{6d}\x{1b}\x{5b}/gr } @lines;

# my @reverse_lines = map { s/$start_esc_seq (?! ${_0m})/$reverse $start_esc_seq/rgx } @lines;

# my @reverse_lines = map { s#\Q$start_esc_seq\E (?! $_0m ) #${reverse}${start_esc_seq}#rgx } @lines;

# my @reverse_lines = map { s#\Q$start_esc_seq\E (?! $_0m ) #${reverse}${start_esc_seq}#gx;
#                           s#\Q$start_esc_seq\E     $_0m   #${start_esc_seq}${_0m}${reverse}#rgx } @lines;

# ESC_SEQ    string    RESET   -->  REVERSE ESC_SEQ    string      RESET  REVERSE

my @reverse_lines = map { s#\Q$start_esc_seq\E (?! $_0m ) #${reverse}${start_esc_seq}#rgx =~
                          s#\Q$start_esc_seq\E     $_0m   #${start_esc_seq}${_0m}${reverse}#rgx =~
                          s# $ #${reset}#rx =~ s#^#${reset}#r                             } @lines;

# my @reverse_lines = map { s#\Q$start_esc_seq\E (?! $_0m ) #${reverse}${start_esc_seq}#rgx =~
#                           s#\Q$start_esc_seq\E     $_0m   #${start_esc_seq}${_0m}${reverse}#rgx =~
#                           s# $ #${reset}#rx                            } @lines;



# my @lines = map { chomp; $_ } (`ls`)[0..10];
# my @lines = map { chomp; $_ } (`ls`)[0..50];
# my @lines = map { chomp; $_ } (`ls`);
my $pos=0;
my ($input,$key) = ("","");
my $prompt;
my ($width, $heigth);
my $columns_to_eol;

($width, $heigth) = GetTerminalSize();
# print $width;

system "tput", "smcup";

while ($key ne "ENTER") {
	system "clear";
	($width, $heigth) = GetTerminalSize();
# 	print $width;
	for (my $i=0; $i < @lines; $i++){
# 	for (my $i=0; $i < 1; $i++){
		if ($i == $pos) {
# 			print REVERSE . GREEN . $lines[$i] . RESET;
# 			print REVERSE . $lines[$i] . RESET;
# 			print $reverse_lines[$i] . REVERSE . " " x ( $width - length $lines[$i]) . RESET;

# 			print length $lines[$i];
# 			print length $reverse_lines[$i];
# 			print length($reverse_lines[$i]) - length($lines[$i]);
# 			print $width - length($reverse_lines[$i]);
# 			print $width - length($lines[$i]);

# 			print $lines[$i] . "o" x ( $width - length $lines[$i]);
# 			print $reverse_lines[$i] . REVERSE . "o" x ( $width - length $lines[$i]) . RESET;


			$columns_to_eol = $width - $length[$i]);
# 			$columns_to_eol = 3 + $width - $length[$i];

# 			print $lines[$i] =~ s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m? //rgx;
# 			print REVERSE . $lines[$i] =~ s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m? //rgx . RESET ;
			print $reverse_lines[$i] . ($columns_to_eol > 0 ? REVERSE . (" " x $columns_to_eol) . RESET : "");

# 			print $reverse_lines[$i], REVERSE . " " x ( $width - length $reverse_lines[$i]) . RESET;
# 			exit;
		}
		else {
# 			print GREEN . $lines[$i] . RESET
			print $lines[$i]
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


print $lines[$pos];

# remove escape sequences
print $lines[$pos] =~ s/ \Q$start_esc_seq\E \d+ (?: ; \d+ )* m? //rgx;

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

london@archlinux:~
$ ls --color=always | hexdump -C | head
00000000  1b 5b 30 6d 1b 5b 30 31  3b 33 32 6d 24 52 31 4a  |.[0m.[01;32m$R1J|
00000010  59 45 31 41 2e 4a 50 47  1b 5b 30 6d 0a 1b 5b 30  |YE1A.JPG.[0m..[0|
00000020  31 3b 33 32 6d 24 52 34  4d 47 51 36 35 2e 6d 70  |1;32m$R4MGQ65.mp|
00000030  33 1b 5b 30 6d 0a 1b 5b  30 31 3b 33 32 6d 24 52  |3.[0m..[01;32m$R|
00000040  50 35 30 38 58 53 2e 4a  50 47 1b 5b 30 6d 0a 1b  |P508XS.JPG.[0m..|
00000050  5b 30 31 3b 33 36 6d 30  61 72 63 68 5f 69 6e 73  |[01;36m0arch_ins|
00000060  74 61 6c 6c 1b 5b 30 6d  0a 1b 5b 30 31 3b 33 36  |tall.[0m..[01;36|
00000070  6d 30 42 49 4f 4c 4f 47  59 1b 5b 30 6d 0a 1b 5b  |m0BIOLOGY.[0m..[|
00000080  30 31 3b 33 34 6d 30 62  69 6f 5f 6e 65 77 1b 5b  |01;34m0bio_new.[|
00000090  30 6d 0a 1b 5b 30 31 3b  33 36 6d 30 43 68 65 61  |0m..[01;36m0Chea|

$ ls --color=always | cat -e | head
^[[0m^[[01;32m$R1JYE1A.JPG^[[0m$
^[[01;32m$R4MGQ65.mp3^[[0m$
^[[01;32m$RP508XS.JPG^[[0m$
^[[01;36m0arch_install^[[0m$
^[[01;36m0BIOLOGY^[[0m$
^[[01;34m0bio_new^[[0m$
^[[01;36m0Cheat Sheets^[[0m$
^[[01;34m0chromium^[[0m$
^[[01;34m0chromium_source^[[0m$
^[[01;36m0Desktop^[[0m$


man ascii.7

RESET ^[[0m   \e[0m
27    1B    ESC (escape)
91    5B    [
48    30    0
109   6D    m

^[[01;32m
27    1B    ESC (escape)
91    5B    [
49    31    1

^[[0m





1b 5b 30 6d 1b 5b 30 31  3b 33 32 6d

24 52 31 4a  |.[0m.[01;32m$R1J| 59 45 31 41 2e 4a 50 47  1b 5b 30 6d 0a

1b 5b 30  |YE1A.JPG.[0m..[0| 31 3b 33 32 6d 24 52 34  4d 47 51 36 35 2e 6d 70  |1;32m$R4MGQ65.mp| 33 1b 5b 30 6d 0a

1b 5b  30 31 3b 33 32 6d 24 52  |3.[0m..[01;32m$R| 50 35 30 38 58 53 2e 4a  50 47 1b 5b 30 6d 0a

1b  |P508XS.JPG.[0m..| 5b 30 31 3b 33 36 6d 30  61 72 63 68 5f 69 6e 73  |[01;36m0arch_ins| 74 61 6c 6c 1b 5b 30 6d  0a

1b 5b 30 31 3b 33 36  |tall.[0m..[01;36| 6d 30 42 49 4f 4c 4f 47  59 1b 5b 30 6d 0a

1b 5b  |m0BIOLOGY.[0m..[| 30 31 3b 33 34 6d 30 62  69 6f 5f 6e 65 77 1b 5b  |01;34m0bio_new.[| 30 6d 0a

1b 5b 30 31 3b  33 36 6d 30 43 68 65 61  |0m..[01;36m0Chea|



london@archlinux:~/perl/scripts/equations/equations
$ ack 'copy_' | ~/perl/scripts/ranger_like/menu.pl
london@archlinux:~/perl/scripts/equations/equations
$ ack 'copy_' | ~/perl/scripts/ranger_like/menu.pl | hexdump -C | head -10
00000000  1b 5b 3f 31 30 34 39 68  1b 5b 48 1b 5b 32 4a 1b  |.[?1049h.[H.[2J.|
00000010  5b 30 6d 1b 5b 37 6d 1b  5b 33 35 6d 73 76 67 2f  |[0m.[7m.[35msvg/|
00000020  65 71 75 61 74 69 6f 6e  73 5f 6f 62 6a 2e 70 6c  |equations_obj.pl|
00000030  1b 5b 30 6d 1b 5b 37 6d  3a 1b 5b 37 6d 1b 5b 33  |.[0m.[7m:.[7m.[3|
00000040  32 6d 34 38 34 1b 5b 30  6d 1b 5b 37 6d 3a 23 09  |2m484.[0m.[7m:#.|
00000050  09 24 73 6f 6c 75 74 69  6f 6e 20 3d 20 1b 5b 37  |.$solution = .[7|
00000060  6d 1b 5b 33 31 3b 31 6d  63 6f 70 79 5f 1b 5b 30  |m.[31;1mcopy_.[0|
00000070  6d 1b 5b 37 6d 64 61 74  61 5f 73 74 72 75 63 74  |m.[7mdata_struct|
00000080  75 72 65 28 24 65 71 29  3b 1b 5b 30 6d 1b 5b 37  |ure($eq);.[0m.[7|
00000090  6d 1b 5b 37 6d 1b 5b 4b  1b 5b 30 6d 0a 1b 5b 33  |m.[7m.[K.[0m..[3|
london@archlinux:~/perl/scripts/equations/equations
$


perl -MTerm::ReadKey -My -le '($width,$heigth)=GetTerminalSize(); $,="\n"; print $width; print REVERSE . " "x$width.RESET'









