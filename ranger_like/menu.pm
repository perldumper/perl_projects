
package menu;
use strict;
use warnings;

use constant    RESET => "\e[0m";
use constant  REVERSE => "\e[7m";	# highlighting

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


sub new {
    my $class = shift;

    # because REVERSE on tabs doesn't make highlighting
    my @lines = map {chomp; s/\t/ " " x 8 /erg } @_;
    chomp @lines;

my @length;
my @reverse_lines;
my $colored_input = $lines[0] =~ /\Q${reset}\E | \x{1B}\x{5B}\x{6D} /x ? 1 : 0 ;
my @lines_text;

    if ($colored_input) {
        @reverse_lines = map {    s#\Q$start_esc_seq\E (?! $_0m ) #${reverse}${start_esc_seq}#rgx
                               =~ s#\Q$start_esc_seq\E     $_0m   #${start_esc_seq}${_0m}${reverse}#rgx
                               =~ s# $ #${reset}#rx
                             } @lines;

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
        @length = map { length } @lines;
    }

    bless \@lines, $class;
}


1;
__END__

new
-> store all the lines
-> reverse





