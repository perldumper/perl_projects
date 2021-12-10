#!/usr/bin/perl

# NOT FINISHED, IN PROCESS
# https://github.com/antlr/grammars-v4/blob/master/pcre/PCRE.g4

use strict;
use warnings;

exit unless @ARGV;
my $regex = shift;

sub tokenize;

# TOKEN STREAM
sub curr;
sub peek;
sub advance;
sub take;

# RULES
sub parse;			# TOP RULE
sub alternation;
sub expr;
sub element;
sub quantifier;
sub quantifier_type;
sub character_class;
sub backreference;
sub backreference_or_octal;
sub capture;
sub non_capture;
sub comment;
sub option;
sub option_flags;
sub option_flag;
sub look_around;
sub subroutine_reference;
sub conditional;
sub backtrack_control;
sub newline_convention;
sub callout;
sub atom;
sub cc_atom;
sub shared_atom;
sub literal;
sub cc_literal;
sub shared_literal;
sub number;
sub octal_char;
sub octal_digit;
sub digits;
sub digit;
sub name;
sub alpha_nums;
sub non_close_parens;
sub non_close_paren;
sub letter;

#  : '[[:' AlphaNumerics ':]]'			\\ POSIXNamedSet
#  : '[[:^' AlphaNumerics ':]]'			\\ POSIXNegatedNamedSet

sub tokenize {
	my $tokens = shift;
	my @characters = split "", $tokens;
	my @tokens;
	while (my $char = shift @characters) {
		if ($char eq "\\") {
			$char = shift @characters;
			if ($char eq "a") {				# BellChar
				push @tokens, "\\a";
			}
			elsif ($char eq "c") {			# ControlChar
				push @tokens, "\\c";
			}
			elsif ($char eq "e") {			# EcapeChar
				push @tokens, "\\e";
			}
			elsif ($char eq "f") {			# FormFeed
				push @tokens, "\\f";
			}
			elsif ($char eq "n") {			# NewLine
				push @tokens, "\\n";
			}
			elsif ($char eq "r") {			# CarriageReturn
				push @tokens, "\\r";
			}
			elsif ($char eq "t") {			# Tab
				push @tokens, "\\t";
			}
			elsif ($char eq "x") {			# HexChar
				push @tokens, "\\x";
			}
			elsif ($char eq "C") {			# OneDataUnit
				push @tokens, "\\C";
			}
			elsif ($char eq "d") {			# DecimalDigit
				push @tokens, "\\d";
			}
			elsif ($char eq "D") {			# NotDecimalDigit
				push @tokens, "\\D";
			}
			elsif ($char eq "h") {			# HorizontalWhiteSpace
				push @tokens, "\\h";
			}
			elsif ($char eq "H") {			# NotHorizontalWhiteSpace
				push @tokens, "\\H";
			}
			elsif ($char eq "N") {			# NotNewLine
				push @tokens, "\\N";
			}
			elsif ($char eq "p") {			# CharWithProperty
				$char = shift @characters;
				if ($char eq "{") {
					push @tokens, "\\p{";
				}
				else {
					push @tokens, "\\", "p", $char;
				}
			}
			elsif ($char eq "P") {			# CharWithoutProperty
				$char = shift @characters;
				if ($char eq "{") {
					push @tokens, "\\P{";
				}
				else {
					push @tokens, "\\", "P", $char;
				}
			}
			elsif ($char eq "R") {			# NewLineSequence
				push @tokens, "\\R";
			}
			elsif ($char eq "s") {			# WhiteSpace
				push @tokens, "\\s";
			}
			elsif ($char eq "S") {			# NotWhiteSpace
				push @tokens, "\\S";
			}
			elsif ($char eq "v") {			# VerticalWhiteSpace
				push @tokens, "\\v";
			}
			elsif ($char eq "V") {			# NotVerticalWhiteSpace
				push @tokens, "\\V";
			}
			elsif ($char eq "w") {			# WordChar
				push @tokens, "\\w";
			}
			elsif ($char eq "W") {			# NotWordChar
				push @tokens, "\\W";
			}
			elsif ($char eq "X") {			# ExtendedUnicodeChar
				push @tokens, "\\X";
			}
			elsif ($char eq "g") {			# named backreference
				push @tokens, "\\g";
			}
			elsif ($char eq "k") {			# named backreference
				push @tokens, "\\k";
			}
			elsif ($char eq "Q") {			# BlockQuoted
				push @tokens, "\\Q";
			}
			elsif ($char eq "E") {			# BlockQuoted
				push @tokens, "\\E";
			}
			elsif ($char eq "b") {			# WordBoundary
				push @tokens, "\\b";
			}
			elsif ($char eq "B") {			# NonWordBoundary
				push @tokens, "\\B";
			}
			elsif ($char eq "A") {			# StartOfSubject
				push @tokens, "\\A";
			}
			elsif ($char eq "Z") {			# EndOfSubjectOrLineEndOfSubject
				push @tokens, "\\Z";
			}
			elsif ($char eq "z") {			# EndOfSubject
				push @tokens, "\\z";
			}
			elsif ($char eq "G") {			# PreviousMatchInSubject
				push @tokens, "\\G";
			}
			elsif ($char eq "K") {			# ResetStartMatch
				push @tokens, "\\K";
			}
			elsif ($char eq "0"				# backreference, reference by number
				or $char eq "1"
				or $char eq "2"
				or $char eq "3"
				or $char eq "4"
				or $char eq "5"
				or $char eq "6"
				or $char eq "7"
				or $char eq "8"
				or $char eq "9") {
				push @tokens, "\\$char";
			}
			else {							# Backslash
				push @tokens, "\\", defined $char ? $char : ();
			}
		}
		#  : '[[:' AlphaNumerics ':]]'			\\ POSIXNamedSet
		#  : '[[:^' AlphaNumerics ':]]'			\\ POSIXNegatedNamedSet
		elsif ($char eq "[") {
			$char = shift @characters;
			if ($char eq "[") {
				$char = shift @characters;
				if ($char eq ":") {
					$char = shift @characters;
					if ($char eq "^") {
						push @tokens, "[[:^";
					}
					else {
						push @tokens, "[", "[", ":", defined $char ? $char : ();
						# OR
						push @tokens, "[", "[", ":";
						if (defined $char) {
							unshift @characters, $char;
							redo;
						}
					}
				}
				else {
					push @tokens, "[", "[", defined $char ? $char : ();	# what if $char is "\\" or other metacharacter or specific case ?
					# OR
					push @tokens, "[", "[";
					if (defined $char) {
						unshift @characters, $char;
						redo;
					}
				}
			}
			else {
				push @tokens, "[", defined $char ? $char : ();
				# OR
				push @tokens, "[";
				if (defined $char) {
					unshift @characters, $char;
					redo;
				}
			}
		}
		elsif ($char eq ":") {
			$char = shift @characters;
			if ($char eq "]") {
				$char = shift @characters;
				if ($char eq "]") {
					push @tokens, ":]]";
				}
				else {
					push @tokens, ":", "]", defined $char ? $char : ();
					# OR
					push @tokens, ":", "]";
					if (defined $char) {
						unshift @characters, $char;
						redo;
					}
				}
			}
			else {
				push @tokens, ":", defined $char ? $char : ();
				# OR
				push @tokens, ":";
				if (defined $char) {
					unshift @characters, $char;
					redo;
				}
			}
		}
		else {
			push @tokens, $char;
		}
	}
	return @tokens;
}

my @tokens = tokenize($regex);

$\="\n";
$,="\n";

# ./pcre.pl 'a?\w\s\S\b\1\5'
# ./pcre.pl 'a?\w\s\S\b\1\55'
# ./pcre.pl 'a?\w\s\S\b\1\T[^&%++/.]'

# print @tokens;
# exit;

my $pos = 0;

sub curr {		# current token in the input stream
	if (defined $tokens[$pos]) {
		return $tokens[$pos]
	}
	else {
		return ""
	}
}

sub peek {		# next token in the token stream / lookahead
	if (defined $tokens[$pos+1]) {
		return $tokens[$pos+1]
	}
	else {
		return ""
	}
}

sub advance {
	$pos++;
}

sub take {		# verify that the currrent token is what is expected and advance in the token stream
	my $token = shift;
	if ($token eq $tokens[$pos]) {
		$pos++;
	}
	else {
		die "wrong token\n";
	}
}



# Most single line comments above the lexer- and  parser rules 
# are copied from the official PCRE man pages (last updated: 
# 10 January 2012): http://www.pcre.org/pcre.txt
# parse
#  : alternation EOF
#  ;

sub parse {
	my $alternation = alternation();
	if (check_EOF()) {
# 		return $alternation;
		return {} # $alternation;
	}
	else {
		# not EOF
	}
}

# ALTERNATION
#
#         expr|expr|expr...
# alternation
#  : expr ('|' expr)*
#  ;

sub alternation {
	my $expr_1 = expr();
# 	my $expr_2;
# 	if (curr() eq "|") {
# 		$expr_2 = expr();
# 	}
		
}

# expr
#  : element*
#  ;

sub expr {
	my @element;
	my $position = $pos;	# save position for backtracking
	while (my $element = element()) {
		$position = $pos;
		push @element, $element
	}
	$pos = $position;
	if (@element) {
		return { type => "expr", value => \@element }
	}
	else {
		return { type => "expr", value => [] }
	}
}

# element
#  : atom quantifier?
#  ;

sub element {
	my $atom = atom();
	my $quantifier;
	if (curr() eq "?") {
		$quantifier = quantifier();
	}
	elsif (curr() eq "+") {
		$quantifier = quantifier();
	}
	elsif (curr() eq "*") {
		$quantifier = quantifier();
	}
	elsif (curr() eq "{") {
		$quantifier = quantifier();
	}
}

# QUANTIFIERS
#
#         ?           0 or 1, greedy
#         ?+          0 or 1, possessive
#         ??          0 or 1, lazy
#         *           0 or more, greedy
#         *+          0 or more, possessive
#         *?          0 or more, lazy
#         +           1 or more, greedy
#         ++          1 or more, possessive
#         +?          1 or more, lazy
#         {n}         exactly n
#         {n,m}       at least n, no more than m, greedy
#         {n,m}+      at least n, no more than m, possessive
#         {n,m}?      at least n, no more than m, lazy
#         {n,}        n or more, greedy
#         {n,}+       n or more, possessive
#         {n,}?       n or more, lazy
# quantifier
#  : '?' quantifier_type
#  | '+' quantifier_type
#  | '*' quantifier_type
#  | '{' number '}'            quantifier_type
#  | '{' number ',' '}'        quantifier_type
#  | '{' number ',' number '}' quantifier_type
#  ;

sub quantifier {
	my $quantifier_type;
	my $number_min;
	my $number_max;
	if (curr() eq "?") {
		take("?");
		$quantifier_type = quantifier_type();
		return { type => "quantifier", value => "?" }
	}
	elsif (curr() eq "+") {
		take("+");
		$quantifier_type = quantifier_type();
		return { type => "quantifier", value => "+" }
	}
	elsif (curr() eq "*") {
		take("*");
		$quantifier_type = quantifier_type();
		return { type => "quantifier", value => "*" }
	}
	elsif (curr() eq "{") {
		take("{");
		$number_min = number();
		if (curr() eq "}") {		# {n}
			take("}");
			$quantifier_type = quantifier_type();
			return { type => "quantifier", value => "exact",  => $number_min, quantifier_type => $quantifier_type }
		}
		elsif (curr() eq ",") {
			take(",");
			if (curr() eq "}") {	# {n,}
				take("}");
				$quantifier_type = quantifier_type();
				return { type => "quantifier",
                        value => "range",
                          min => $number_min,
                          max => "inf",
              quantifier_type => $quantifier_type }
			}
			# elsif (curr() =~ number) {		# HOW TO VERIFY THIS ???
			else {					# {n,m}
				$number_max = number();
				take("}");
				$quantifier_type = quantifier_type();
				return { type => "quantifier",
                        value => "range",
                          min => $number_min,
                          max => $number_max,
              quantifier_type => $quantifier_type }
			}
		}
	}
}

# quantifier_type
#  : '+'				// possessive
#  | '?'				// lazy
#  | /* nothing */	// greedey
#  ;

sub quantifier_type {
	if (curr() eq "+") {
		take("+");
		return { type => "quantifier_type", value => "possessive" }
	}
	elsif (curr() eq "?") {
		take("?");
		return { type => "quantifier_type", value => "lazy" }
	}
	else {
		return { type => "quantifier_type", value => "greedy" }
	}
}


# CHARACTER CLASSES
#
#         [...]       positive character class
#         [^...]      negative character class
#         [x-y]       range (can be used for hex characters)
#         [[:xxx:]]   positive POSIX named set
#         [[:^xxx:]]  negative POSIX named set
#
#         alnum       alphanumeric
#         alpha       alphabetic
#         ascii       0-127
#         blank       space or tab
#         cntrl       control character
#         digit       decimal digit
#         graph       printing, excluding space
#         lower       lower case letter
#         print       printing, including space
#         punct       printing, excluding alphanumeric
#         space       white space
#         upper       upper case letter
#         word        same as \w
#         xdigit      hexadecimal digit
#
#       In PCRE, POSIX character set names recognize only ASCII  characters  by
#       default,  but  some  of them use Unicode properties if PCRE_UCP is set.
#       You can use \Q...\E inside a character class.
# character_class
#  : '[' '^' ']' '-' cc_atom+ ']'
#  | '[' '^' ']'     cc_atom* ']'
#  | '[' '^'         cc_atom+ ']'
#  | '[' ']'     '-' cc_atom+ ']'
#  | '[' ']'         cc_atom* ']'
#  | '['             cc_atom+ ']'
#  ;

sub character_class {
	my $cc_atom;
	take("[");
	if (curr() eq "^") {
		take("^");
		if (curr() eq "-") {
			take("-");
		}
	}
	elsif (curr() eq "]") {
		take("]");
	}
	else {	# cc_atom
	}
}


# BACKREFERENCES
#
#         \n              reference by number (can be ambiguous)
#         \gn             reference by number
#         \g{n}           reference by number
#         \g{-n}          relative reference by number
#         \k<name>        reference by name (Perl)
#         \k'name'        reference by name (Perl)
#         \g{name}        reference by name (Perl)
#         \k{name}        reference by name (.NET)
#         (?P=name)       reference by name (Python)
# backreference
#  : backreference_or_octal
#  | '\\g'         number
#  | '\\g'     '{' number '}'
#  | '\\g' '{' '-' number '}'
#  | '\\g'       '{' name '}'
#  | '\\k'       '<' name '>'
#  | '\\k'      '\'' name '\''
#  | '\\k'       '{' name '}'
#  | '(' '?' 'P' '=' name ')'
#  ;

sub backreference {
	my $number;
	my $name;
	if (curr() eq "\\g") {
		take("\\g");
		if (curr() eq "{") {
			advance();
			if (curr() eq "-") {		# \g{-n}
				advance();
				$number = number();
				take("}");
				return { type=> "backreference", }
			}
# 			if (curr() =~ number) {		# \g{n}
# 				$number = number();
# 				take("}");
# 				return {}
# 			}
# 			elsif (curr() =~ name) {	# \g{name}
# 				$name = name();
# 				take("}");
# 				return {}
# 			}
		}
		$number = number();
		return {type=> "backreference"}
	}
	elsif (curr() eq "\\k") {			# \k
		advance();
	}
}

# backreference_or_octal
#  : octal_char
#  | '\\' digit
#  ;

sub backreference_or_octal {
	my $digit;
	my $octal_char;
	if (curr() eq "\\") {
		advance();
		$digit = digit();
		return { type => "backreference", value => $digit }
	}
	else {
		$octal_char = octal_char();
		return { type => "ocatal", value => $octal_char }
	}
}

# CAPTURING
#
#         (...)           capturing group
#         (?<name>...)    named capturing group (Perl)
#         (?'name'...)    named capturing group (Perl)
#         (?P<name>...)   named capturing group (Python)
#         (?:...)         non-capturing group
#         (?|...)         non-capturing group; reset group numbers for
#                          capturing groups in each alternative
#
# ATOMIC GROUPS
#
#         (?>...)         atomic, non-capturing group
# capture
#  : '(' '?'     '<' name '>'  alternation ')'
#  | '(' '?'    '\'' name '\'' alternation ')'
#  | '(' '?' 'P' '<' name '>'  alternation ')'
#  | '(' alternation ')'
#  ;

sub capture {
	my $name;
	my $alternation;
	take("(");
	if (curr() eq "?") {
		take("?");
		if (curr() eq "<") {		# (?<name>)
			advance();
			$name = name();
			take(">");
			$alternation = alternation();
			take(")");
			return { type => "capture", subtype => "named", name => $name, alternation => $alternation}
		}
		elsif (curr() eq "'") {	# (?'name')
			advance();
			$name = name();
			take("\\");
			$alternation = alternation();
			take(")");
			return { type => "capture", subtype => "named", name => $name, alternation => $alternation}
		}
		elsif (curr() eq "P") {		# (?P<name>)
			advance();
			take("<");
			$name = name();
			take(">");
			$alternation = alternation();
			take(")");
			return { type => "capture", subtype => "named", name => $name, alternation => $alternation}
		}
	}
	else {							# ()
		$alternation = alternation();
		take(")");
		return { type => "capture", subtype => "numbered", alternation => $alternation}

	}
}

# non_capture
#  : '(' '?' ':'              alternation ')'
#  | '(' '?' '|'              alternation ')'
#  | '(' '?' '>'              alternation ')'
#  | '(' '?' option_flags ':' alternation ')'
#  ;

sub non_capture {
	my $option_flags;
	my $alternation;
	take("(");
	take("?");
	if (curr() eq ":") {		# (?:)
		advance();
		$alternation = alternation();
		take(")");
		return { type => "non-capturing", alternation => $alternation }
	}
	elsif (curr() eq "|") {		# (?|)
		advance();
		$alternation = alternation();
		take(")");
		return { type => "branch-reset", alternation => $alternation }
	}
	elsif (curr() eq ">") {		# (?>)
		advance();
		$alternation = alternation();
		take(")");
		return { type => "atomic", alternation => $alternation }
	}
	my $position = $pos;
	if ($option_flags = option_flags()) {	# (?i)
		take(":");
		$alternation = alternation();
		take(")");
		return { type => "non-capturing", falgs => $option_flags,alternation => $alternation }
	}
	else {
		$pos = $position;
		return 0;
		# die "error in parsing option_flags";
	}
}

# COMMENT
#
#         (?#....)        comment (not nestable)
# comment
#  : '(' '?' '#' non_close_parens ')'
#  ;

sub comment {
	take("(");
	take("?");
	take("#");
	my $comment = non_close_parens();
	take(")");
	return {type => "comment", comment => $comment}
}

# OPTION SETTING
#
#         (?i)            caseless
#         (?J)            allow duplicate names
#         (?m)            multiline
#         (?s)            single line (dotall)
#         (?U)            default ungreedy (lazy)
#         (?x)            extended (ignore white space)
#         (?-...)         unset option(s)
#
#       The following are recognized only at the start of a  pattern  or  after
#       one of the newline-setting options with similar syntax:
#
#         (*NO_START_OPT) no start-match optimization (PCRE_NO_START_OPTIMIZE)
#         (*UTF8)         set UTF-8 mode: 8-bit library (PCRE_UTF8)
#         (*UTF16)        set UTF-16 mode: 16-bit library (PCRE_UTF16)
#         (*UCP)          set PCRE_UCP (use Unicode properties for \d etc)
# option
#  : '(' '?' option_flags '-' option_flags ')'						\\ (?option_flags-option_flags)
#  | '(' '?'                  option_flags ')'						\\ (?option_flags)
#  | '(' '?'              '-' option_flags ')'						\\ (?-option_flags)
#  | '(' '*' 'N' 'O' '_' 'S' 'T' 'A' 'R' 'T' '_' 'O' 'P' 'T' ')'		\\ (*NO_START_OPT)
#  | '(' '*' 'U' 'T' 'F' '8' ')'										\\ (*UTF8)
#  | '(' '*' 'U' 'T' 'F' '1' '6' ')'									\\ (*UTF16)
#  | '(' '*' 'U' 'C' 'P' ')'											\\ (*UCP)
#  ;

sub option {
}

# option_flags
#  : option_flag+
#  ;

sub option_flags {			# REQUIRE TO SAVE THE $pos POSITION IN THE INPUT STREAM FOR BEING ABLE TO BACKTRACK
	my @option_flag;
	my $position = $pos;
	while (my $option_flag = option_flag()) {
		$position = $pos;
		push @option_flag, $option_flag;
	}
	$pos = $position;
	if (@option_flag >= 1) {
		return { type => "option_flags", value => \@option_flag}
	}
	else {
		return 0;
	}
}

# option_flag
#  : 'i'			\\ case insensitive
#  | 'J'			\\ allows the use of duplicate named groups
#  | 'm'			\\ multiline ^ $ start and end of string AND after and before a newline character \n
#  | 's'			\\ . dot match also newline \n
#  | 'U'			\\ invert the greediness ==> not lazy by default .*? become greedy
#  | 'x'			\\ ignore whitespace except when escaped or inside character class
#  ;

sub option_flag {
	if (curr() eq "i") {
		advance();
		return { type => "option_flag", value => "i" }
	}
	elsif (curr() eq "J") {
		advance();
		return { type => "option_flag", value => "J" }
	}
	elsif (curr() eq "m") {
		advance();
		return { type => "option_flag", value => "m" }
	}
	elsif (curr() eq "s") {
		advance();
		return { type => "option_flag", value => "s" }
	}
	elsif (curr() eq "U") {
		advance();
		return { type => "option_flag", value => "U" }
	}
	elsif (curr() eq "x") {
		advance();
		return { type => "option_flag", value => "x" }
	}
}


# LOOKAHEAD AND LOOKBEHIND ASSERTIONS
#
#         (?=...)         positive look ahead
#         (?!...)         negative look ahead
#         (?<=...)        positive look behind
#         (?<!...)        negative look behind
#
#       Each top-level branch of a look behind must be of a fixed length.
# look_around
#  : '(' '?' '='     alternation ')'
#  | '(' '?' '!'     alternation ')'
#  | '(' '?' '<' '=' alternation ')'
#  | '(' '?' '<' '!' alternation ')'
#  ;

sub look_around {
	my $alternation;
	take("(");
	take("?");
	if (curr() eq "=") {		# (?=)
		advance();
		$alternation = alternation();
		take(")");
		return { type=> "look_around", sub_type=> "positive_lookahead", alternation=> $alternation };
	}
	elsif (curr() eq "!") {		# (?!)
		advance();
		$alternation = alternation();
		take(")");
		return { type=> "look_around", sub_type=> "negative_lookahead", alternation=> $alternation };
	}
	elsif (curr() eq "<") {
		advance();
		if (curr() eq "=") {	# (?<=)
			advance();
			$alternation = alternation();
			take(")");
			return { type=> "look_around", sub_type=> "positive_lookbehind", alternation=> $alternation };
		}
		elsif (curr() eq "!") {	# (?<!)
			advance();
			$alternation = alternation();
			take(")");
			return { type=> "look_around", sub_type=> "negative_lookbehind", alternation=> $alternation };
		}
	}
}

# SUBROUTINE REFERENCES (POSSIBLY RECURSIVE)
#
#         (?R)            recurse whole pattern
#         (?n)            call subpattern by absolute number
#         (?+n)           call subpattern by relative number
#         (?-n)           call subpattern by relative number
#         (?&name)        call subpattern by name (Perl)
#         (?P>name)       call subpattern by name (Python)
#         \g<name>        call subpattern by name (Oniguruma)
#         \g'name'        call subpattern by name (Oniguruma)
#         \g<n>           call subpattern by absolute number (Oniguruma)
#         \g'n'           call subpattern by absolute number (Oniguruma)
#         \g<+n>          call subpattern by relative number (PCRE extension)
#         \g'+n'          call subpattern by relative number (PCRE extension)
#         \g<-n>          call subpattern by relative number (PCRE extension)
#         \g'-n'          call subpattern by relative number (PCRE extension)
# subroutine_reference
#  : '(' '?'          'R' ')'
#  | '(' '?'       number ')'
#  | '(' '?' '+'   number ')'
#  | '(' '?' '-'   number ')'
#  | '(' '?' '&'     name ')'
#  | '(' '?' 'P' '>' name ')'
#  | '\\g' '<'       name '>'
#  | '\\g' '<'      number '>'
#  | '\\g' '<'  '+' number '>'
#  | '\\g' '<'  '-' number '>'
#  | '\\g' '\''      name '\''
#  | '\\g' '\''     number '\''
#  | '\\g' '\'' '+' number '\''
#  | '\\g' '\'' '-' number '\''
#  ;

sub subroutine_reference {
	my $number;
	my $name;
	my $position = $pos;
	if (curr() eq "(") {
		take("(");
		if (curr() eq "?") {
			take("?");
			if (curr() eq "R") {		# (?R)
				take("R");
				take(")");
				return { type => "subroutine_reference", value => "" }
			}
			elsif (curr() eq "+") {		# (?+n)
				take("+");
				$number = number();
				take(")");
				return { type => "subroutine_reference", value => "" }
			}
			elsif (curr() eq "-") {		# (?-m)
				take("-");
				$number = number();
				take(")");
				return { type => "subroutine_reference", value => "" }
			}
			elsif (curr() eq "&") {		# (?&name)
				take("&");
				$name = name();
				take(")");
				return { type => "subroutine_reference", value => "" }
			}
			elsif (curr() eq "P") {		# (?P>name)
				take("P");
				take(">");
				$name = name();
				take(")");
				return { type => "subroutine_reference", value => "" }
			}
# 			elsif (curr() =~ number) {	# (?n)
# 				$number = number();
# 				take(")");
				return { type => "subroutine_reference", value => "" }
# 			}
		}
	}
	elsif (curr() eq "\\g") {
		take("\\g");
		if (curr() eq "<") {
			take("<");
			if (curr() eq "+") {			# \g<+n>
				take("+");
				$number = number();
				take(">");
				return { type => "subroutine_reference", value => "" }
			}
			elsif (curr() eq "-") {			# \g<-n>
				take("-");
				$number = number();
				take(">");
				return { type => "subroutine_reference", value => "" }
			}
# 			elsif (curr() =~ name) {		# \g<name>
# 				$name = name();
# 				take(">");
# 				return { type => "subroutine_reference", value => "" }
# 			}
# 			elsif (curr() =~ number) {		# \g<n>
# 				$number = number();
# 				take(">");
# 				return { type => "subroutine_reference", value => "" }
# 			}
		}
		elsif (curr() eq "'") {
			take("'");
			if (curr() eq "+") {			# \g'+n'
				take("+");
				$number = number();
				take("'");
				return { type => "subroutine_reference", value => "" }
			}
			elsif (curr() eq "-") {			# \g'-n'
				take("-");
				$number = number();
				take("'");
				return { type => "subroutine_reference", value => "" }
			}
# 			elsif (curr() =~ name) {		# \g'name'
# 				$name = name();
# 				take("'");
# 				return { type => "subroutine_reference", value => "" }
# 			}
# 			elsif (curr() =~ number) {		# \g'n'
# 				$number = number();
# 				take("'");
# 				return { type => "subroutine_reference", value => "" }
# 			}
		}
	}
}


# CONDITIONAL PATTERNS
#
#         (?(condition)yes-pattern)
#         (?(condition)yes-pattern|no-pattern)
#
#         (?(n)...        absolute reference condition
#         (?(+n)...       relative reference condition
#         (?(-n)...       relative reference condition
#         (?(<name>)...   named reference condition (Perl)
#         (?('name')...   named reference condition (Perl)
#         (?(name)...     named reference condition (PCRE)
#         (?(R)...        overall recursion condition
#         (?(Rn)...       specific group recursion condition
#         (?(R&name)...   specific recursion condition
#         (?(DEFINE)...   define subpattern for reference
#         (?(assert)...   assertion condition
# conditional
#  : '(' '?' '('         number          ')' alternation ('|' alternation)? ')'
#  | '(' '?' '(' '+'     number          ')' alternation ('|' alternation)? ')'
#  | '(' '?' '(' '-'     number          ')' alternation ('|' alternation)? ')'
#  | '(' '?' '(' '<'       name '>'      ')' alternation ('|' alternation)? ')'
#  | '(' '?' '(' '\''      name '\''     ')' alternation ('|' alternation)? ')'
#  | '(' '?' '(' 'R'     number          ')' alternation ('|' alternation)? ')'
#  | '(' '?' '(' 'R'                     ')' alternation ('|' alternation)? ')'
#  | '(' '?' '(' 'R' '&'   name          ')' alternation ('|' alternation)? ')'
#  | '(' '?' '(' 'D' 'E' 'F' 'I' 'N' 'E' ')' alternation ('|' alternation)? ')'
#  | '(' '?' '(' 'a' 's' 's' 'e' 'r' 't' ')' alternation ('|' alternation)? ')'
#  | '(' '?' '('           name          ')' alternation ('|' alternation)? ')'
#  ;

sub conditional {
	my $number;
	my $name;
	my $alternation;
	take("(");
	take("?");
	take("(");
	if (curr() eq "+") {
		take("+");
		$number = number();
		take(")");
		$alternation = alternation();
		if (curr() eq "|") {				# (?(+n))
			take("|");
			$alternation = alternation();
			
		}
		take(")");			# TO VERIFY
		return {};
	}
	elsif (curr() eq "-") {
		take("-");
		$number = number();
		take(")");
		$alternation = alternation();
		if (curr() eq "|") {
			take("|");
			$alternation = alternation();
			
		}
		take(")");
		return {};
	}
	elsif (curr() eq "<") {
		take("<");
		$name = name();
		take(">");
		take(")");
		$alternation = alternation();
		if (curr() eq "|") {
			take("|");
			$alternation = alternation();
			
		}
		take(")");
		return {};
	}
	elsif (curr() eq "\\") {
		take("\\");
		$name = name();
		take("\\");
		take(")");
		$alternation = alternation();
		if (curr() eq "|") {
			take("|");
			$alternation = alternation();
			
		}
		take(")");
		return {};
	}
	elsif (curr() eq "R") {
		take("R");
		if (curr() eq ")") {
			take(")");
			$alternation = alternation();
			if (curr() eq "|") {
				take("|");
				$alternation = alternation();
				
			}
			take(")");
			return {};
		}
		elsif (curr() eq "&") {
			take("&");
			$name = name();
			take(")");
			$alternation = alternation();
			if (curr() eq "|") {
				take("|");
				$alternation = alternation();
				
			}
			take(")");
			return {};
		}
# 		elsif (curr() =~ number) {
# 			$number = number();
# 			take(")");
# 			$alternation = alternation();
# 			if (curr() eq "|") {
# 				take("|");
# 				$alternation = alternation();
# 				
# 			}
# 			take(")");
# 			return {};
# 		}
	}
	elsif (curr() eq "D") {
		take("D");
		take("E");
		take("F");
		take("I");
		take("N");
		take("E");
		take(")");
		$alternation = alternation();
		if (curr() eq "|") {
			take("|");
			$alternation = alternation();
			
		}
		take(")");
		return {};
	}
	elsif (curr() eq "a") {
		take("a");
		take("s");
		take("s");
		take("e");
		take("r");
		take("t");
		take(")");
		$alternation = alternation();
		if (curr() eq "|") {
			take("|");
			$alternation = alternation();
			
		}
		take(")");
		return {};
	}
# 	elsif (curr() =~ number) {
# 		$number = number();
# 		take(")");
# 		$alternation = alternation();
# 		if (curr() eq "|") {
# 			take("|");
# 			$alternation = alternation();
# 			
# 		}
# 		take(")");
# 		return {};
# 	}
# 	elsif (curr() =~ name) {
# 		$name = name();
# 		take(")");
# 		$alternation = alternation();
# 		if (curr() eq "|") {
# 			take("|");
# 			$alternation = alternation();
# 			
# 		}
# 		take(")");
# 		return {};
# 	}
}

# BACKTRACKING CONTROL
#
#       The following act immediately they are reached:
#
#         (*ACCEPT)       force successful match
#         (*FAIL)         force backtrack; synonym (*F)
#         (*MARK:NAME)    set name to be passed back; synonym (*:NAME)
#
#       The  following  act only when a subsequent match failure causes a back-
#       track to reach them. They all force a match failure, but they differ in
#       what happens afterwards. Those that advance the start-of-match point do
#       so only if the pattern is not anchored.
#
#         (*COMMIT)       overall failure, no advance of starting point
#         (*PRUNE)        advance to next starting character
#         (*PRUNE:NAME)   equivalent to (*MARK:NAME)(*PRUNE)
#         (*SKIP)         advance to current matching position
#         (*SKIP:NAME)    advance to position corresponding to an earlier
#                         (*MARK:NAME); if not found, the (*SKIP) is ignored
#         (*THEN)         local failure, backtrack to next alternation
#         (*THEN:NAME)    equivalent to (*MARK:NAME)(*THEN)
# backtrack_control
#  : '(' '*' 'A' 'C' 'C' 'E' 'P' 'T' ')'							// (*ACCEPT)
#  | '(' '*' 'F' ('A' 'I' 'L')? ')'									// (*F(AIL)?)
#  | '(' '*' ('M' 'A' 'R' 'K')? ':' 'N' 'A' 'M' 'E' ')'				// (*(MARK)?:NAME)
#  | '(' '*' 'C' 'O' 'M' 'M' 'I' 'T' ')'							// (*COMMIT)
#  | '(' '*' 'P' 'R' 'U' 'N' 'E' ')'								// (*PRUNE)
#  | '(' '*' 'P' 'R' 'U' 'N' 'E' ':' 'N' 'A' 'M' 'E' ')'			// (*PRUNE:NAME)
#  | '(' '*' 'S' 'K' 'I' 'P' ')'									// (*SKIP)
#  | '(' '*' 'S' 'K' 'I' 'P' ':' 'N' 'A' 'M' 'E' ')'				// (*SKIP:NAME)
#  | '(' '*' 'T' 'H' 'E' 'N' ')'									// (*THEN)
#  | '(' '*' 'T' 'H' 'E' 'N' ':' 'N' 'A' 'M' 'E' ')'				// (*THEN:NAME)
#  ;

sub backtrack_control {
	take("(");
	take("*");
	if (curr() eq "A") {
		take("A");
		take("C");
		take("C");
		take("E");
		take("P");
		take("T");
		take(")");
		return {};
	}
	elsif (curr() eq "F") {
		take("F");
		if (curr() eq "A") {
			take("A");
			take("I");
			take("L");
			return {};
		}
		take(")");
		return {};
	}
	elsif (curr() eq "M") {
		take("M");
		take("A");
		take("R");
		take("K");
		take(":");
		take("N");
		take("A");
		take("M");
		take("E");
		take(")");
		return {};
	}
	elsif (curr() eq ":") {
		take(":");
		take("N");
		take("A");
		take("M");
		take("E");
		take(")");
		return {};
	}
	elsif (curr() eq "C") {
		take("C");
		take("O");
		take("M");
		take("M");
		take("I");
		take("T");
		take(")");
		return {};
	}
	elsif (curr() eq "P") {
		take("P");
		take("R");
		take("U");
		take("N");
		take("E");
		if (curr() eq ":") {
			take(":");
			take("N");
			take("A");
			take("M");
			take("E");
			take(")");
			return {};
		}
		take(")");
		return {};
	}
	elsif (curr() eq "S") {
		take("S");
		take("K");
		take("I");
		take("P");
		if (curr() eq ":") {
			take(":");
			take("N");
			take("A");
			take("M");
			take("E");
			take(")");
			return {};
		}
		take(")");
		return {};
	}
	elsif (curr() eq "T") {
		take("T");
		take("H");
		take("E");
		take("N");
		if (curr() eq ":") {
			take(":");
			take("N");
			take("A");
			take("M");
			take("E");
			take(")");
			return {};
		}
		take(")");
		return {};
	}
}

# NEWLINE CONVENTIONS
#capture
#       These are recognized only at the very start of the pattern or  after  a
#       (*BSR_...), (*UTF8), (*UTF16) or (*UCP) option.
#
#         (*CR)           carriage return only
#         (*LF)           linefeed only
#         (*CRLF)         carriage return followed by linefeed
#         (*ANYCRLF)      all three of the above
#         (*ANY)          any Unicode newline sequence
# #
# WHAT \R MATCHES
# #
#       These  are  recognized only at the very start of the pattern or after a
#       (*...) option that sets the newline convention or a UTF or UCP mode.
# #
#         (*BSR_ANYCRLF)  CR, LF, or CRLF
#         (*BSR_UNICODE)  any Unicode newline sequence
# newline_convention
#  : '(' '*' 'C' 'R' ')'											// (*CR)
#  | '(' '*' 'L' 'F' ')'											// (*LF)
#  | '(' '*' 'C' 'R' 'L' 'F' ')'									// (*CRLF)
#  | '(' '*' 'A' 'N' 'Y' 'C' 'R' 'L' 'F' ')'						// (*ANYCRLF)
#  | '(' '*' 'A' 'N' 'Y' ')'										// (*ANY)
#  | '(' '*' 'B' 'S' 'R' '_' 'A' 'N' 'Y' 'C' 'R' 'L' 'F' ')'		// (*BSR_ANYCRLF)
#  | '(' '*' 'B' 'S' 'R' '_' 'U' 'N' 'I' 'C' 'O' 'D' 'E' ')'		// (*BSR_UNICODE)
#  ;

sub newline_convention {
	take("(");
	take("*");
	if (curr() eq "C") {
		take("C");
		take("R");
		if (curr() eq ")") {
			take(")");
			return { }
		}
		elsif (curr() eq "L") {
			take("L");
			take("F");
			take(")");
			return { }
		}
	}
	elsif (curr() eq "L") {
		take("L");
		take("F");
		take(")");
		return { }
	}
	elsif (curr() eq "A") {
		take("A");
		take("N");
		take("Y");
		if (curr() eq ")") {
			take(")");
			return {}
		}
		elsif (curr() eq "C") {
			take("C");
			take("R");
			take("L");
			take("F");
			take(")");
			return {}
		}
	}
	elsif (curr() eq "B") {
		take("B");
		take("S");
		take("R");
		take("_");
		if (curr() eq "A") {
			take("A");
			take("N");
			take("Y");
			take("C");
			take("R");
			take("L");
			take("F");
			take(")");
			return {}
		}
		elsif (curr() eq "U") {
			take("U");
			take("N");
			take("I");
			take("C");
			take("O");
			take("D");
			take("E");
			take(")");
			return {}
		}
	}
}

# CALLOUTS
#
#         (?C)      callout
#         (?Cn)     callout with data n
# callout
#  : '(' '?' 'C' ')'
#  | '(' '?' 'C' number ')'
#  ;

sub callout {
	my $position = $pos;
	take("(");
	take("?");
	take("C");
	if (curr() eq ")") {
		advance();
		return {};
	}
	if (my $number = number()) {
		take(")");
		return {}
	}
	else {
		$pos = $position;
		return {}
	}
}

# atom
#  : subroutine_reference
#  | shared_atom
#  | literal
#  | character_class
#  | capture
#  | non_capture
#  | comment
#  | option
#  | look_around
#  | backreference
#  | conditional
#  | backtrack_control
#  | newline_convention
#  | callout
#  | '.'			\\ Dot
#  | '^'			\\ Caret
#  | '\\A'		\\ StartOfSubject
#  | '\\b'		\\ WordBoundary
#  | '\\B'		\\ NonWordBoundary
#  | '$'			\\ EndOfSubjectOrLine
#  | '\\Z'		\\ EndOfSubjectOrLineEndOfSubject
#  | '\\z'		\\ EndOfSubject
#  | '\\G'		\\ PreviousMatchInSubject
#  | '\\K'		\\ ResetStartMatch
#  | '\\C'		\\ OneDataUnit
#  | '\\X'		\\ ExtendedUnicodeChar
#  ;

sub atom {
	if (curr() eq ".") {
		advance();
		return {};
	}
	elsif (curr() eq "^") {
		advance();
		return {};
	}
	elsif (curr() eq "\\A") {
		advance();
		return {};
	}
	elsif (curr() eq "\\b") {
		advance();
		return {};
	}
	elsif (curr() eq "\\B") {
		advance();
		return {};
	}
	elsif (curr() eq "\$") {
		advance();
		return {};
	}
	elsif (curr() eq "\\Z") {
		advance();
		return {};
	}
	elsif (curr() eq "\\z") {
		advance();
		return {};
	}
	elsif (curr() eq "\\G") {
		advance();
		return {};
	}
	elsif (curr() eq "\\K") {
		advance();
		return {};
	}
	elsif (curr() eq "\\C") {
		advance();
		return {};
	}
	elsif (curr() eq "\\X") {
		advance();
		return {};
	}
}

# cc_atom
#  : cc_literal '-' cc_literal
#  | cc_literal
#  | shared_atom
#  | backreference_or_octal // only octal is valid in a cc
#  ;

sub cc_atom {
	my @position = $pos;
	if (my $cc_literal_1 = cc_literal()) {
		push @position, $pos;
		if (curr() eq "-") {
			take("-");
			if (my $cc_literal_2 = cc_literal()) {
				return {}		# $cc_literal_1 '-' $cc_literal_2
			}
			else {
				$pos = $position[1];
				return {}		# $cc_literal_1
			}
		}
		else {
			return {}			# $cc_literal_1
		}
	}
	else {
		$pos = $position[0];
	}
	if (my $shared_atom = shared_atom()) {
		return {}
	}
	else {
		$pos = $position[0];
	}
	if (my $backreference_or_octal = backreference_or_octal()) {
		return {}
	}
	else {
		$pos = $position[0];
		return 0;
		# die
	}
}

# shared_atom
#  : '[[:' AlphaNumerics ':]]'			\\ POSIXNamedSet
#  : '[[:^' AlphaNumerics ':]]'			\\ POSIXNegatedNamedSet
#  | '\\c'								\\ ControlChar
#  | '\\d'								\\ DecimalDigit
#  | '\\D'								\\ NotDecimalDigit
#  | '\\h'								\\ HorizontalWhiteSpace
#  | '\\H'								\\ NotHorizontalWhiteSpace
#  | '\\N'								\\ NotNewLine
#  | '\\p{' UnderscoreAlphaNumerics '}'	\\ CharWithProperty
#  | '\\P{' UnderscoreAlphaNumerics '}'	\\ CharWithoutProperty
#  | '\\R'								\\ NewLineSequence
#  | '\\s'								\\ WhiteSpace
#  | '\\S'								\\ NotWhiteSpace
#  | '\\v'								\\ VerticalWhiteSpace
#  | '\\V'								\\ NotVerticalWhiteSpace
#  | '\\w'								\\ WordChar
#  | '\\W'								\\ NotWordChar
#  ;

sub shared_atom {
	my $AlphaNumerics;
	if (curr() eq "[[:") {
		advance();
		$AlphaNumerics = AlphaNumerics();
		take(":]]");
		return {type => "shared-atom", value => ""};
	}
	elsif (curr() eq "[[:^") {
		advance();
		$AlphaNumerics = AlphaNumerics();
		take(":]]");
		return {};
	}
	elsif (curr() eq "\\c") {
		advance();
		return {};
	}
	elsif (curr() eq "\\d") {
		advance();
		return {};
	}
	elsif (curr() eq "\\D") {
		advance();
		return {};
	}
	elsif (curr() eq "\\h") {
		advance();
		return {};
	}
	elsif (curr() eq "\\H") {
		advance();
		return {};
	}
	elsif (curr() eq "\\N") {
		advance();
		return {};
	}
	elsif (curr() eq "\\p") {
		advance();
		return {};
	}
	elsif (curr() eq "\\P") {
		advance();
		return {};
	}
	elsif (curr() eq "\\R") {
		advance();
		return {};
	}
	elsif (curr() eq "\\s") {
		advance();
		return {};
	}
	elsif (curr() eq "\\S") {
		advance();
		return {};
	}
	elsif (curr() eq "\\v") {
		advance();
		return {};
	}
	elsif (curr() eq "\\V") {
		advance();
		return {};
	}
	elsif (curr() eq "\\w") {
		advance();
		return {};
	}
	elsif (curr() eq "\\W") {
		advance();
		return {};
	}
	else {
		return 0;
	}
}

# literal
#  : shared_literal
#  | ']'					\\ CharacterClassEnd
#  ;

sub literal {
	my $position = $pos;
	if (curr() eq "]") {
		advance();
		return {type => "literal", value => "]"}
	}
	if (my $shared_literal = shared_literal()) {
		return { type => "" }
	}
	else {
		$pos = $position;
		return 0;
		# die
	}
}

# cc_literal
#  : shared_literal
#  | '.'					\\ Dot
#  | '['					\\ CharacterClassStart
#  | '^'					\\ Caret
#  | '?'					\\ QuestionMark
#  | '+'					\\ Plus
#  | '*'					\\ Star
#  | '\\b'				\\ WordBoundary
#  | '$'					\\ EndOfSubjectOrLine
#  | '|'					\\ Pipe
#  | '('					\\ OpenParen
#  | ')'					\\ CloseParen
#  ;

sub cc_literal {
	if (curr() eq ".") {
		take(".");
		return { type => "cc-literal", value => "dot" }
	}
	elsif (curr() eq "[") {
		take("[");
		return { type => "cc-literal", value => "openbracket" }
	}
	elsif (curr() eq "^") {
		take("^");
		return { type => "cc-literal", value => "caret" }
	}
	elsif (curr() eq "?") {
		take("?");
		return { type => "cc-literal", value => "interrogation" }
	}
	elsif (curr() eq "+") {
		take("+");
		return { type => "cc-literal", value => "plus" }
	}
	elsif (curr() eq "*") {
		take("*");
		return { type => "cc-literal", value => "star" }
	}
	elsif (curr() eq "\\b") {
		take("\\b");
		return { type => "cc-literal", value => "wordboundary" }
	}
	elsif (curr() eq "\$") {
		take("\$");
		return { type => "cc-literal", value => "dollar" }
	}
	elsif (curr() eq "|") {
		take("|");
		return { type => "cc-literal", value => "pipe" }
	}
	elsif (curr() eq "(") {
		take("(");
		return { type => "cc-literal", value => "openparen" }
	}
	elsif (curr() eq ")") {
		take(")");
		return { type => "cc-literal", value => "closeparen" }
	}
	else {	# elsif shared_literal
		return shared_literal();
	}
}

# shared_literal
#  : octal_char
#  | letter
#  | digit
#  | '\\a'						\\ BellChar
#  | '\\e'						\\ EscapeChar
#  | '\\f'						\\ FormFeed
#  | '\\n'						\\ NewLine
#  | '\\r'						\\ CarriageReturn
#  | '\\t'						\\ Tab
#  | '\\x' ( [0-9a-fA-F] [0-9a-fA-F] | '{' [0-9a-fA-F] [0-9a-fA-F] [0-9a-fA-F]+ '}' )		\\ HexChar
#  | '\\'	~[a-zA-Z0-9]			\\ Quoted -> Backslash NonAlphaNumeric
#  | '\\Q' .*? '\\E'				\\ BlockQuoted
#  | '{'							\\ OpenBrace
#  | '}'							\\ CloseBrace
#  | ','							\\ Comma
#  | '-'							\\ Hyphen
#  | '<'							\\ LessThan
#  | '>'							\\ GreaterThan
#  | '\''							\\ SingleQuote
#  | '_'							\\ Underscore
#  | ':'							\\ Colon
#  | '#'							\\ Hash
#  | '='							\\ Equals
#  | '!'							\\ Exclamation
#  | '&'							\\ Ampersand
#  | .								\\ OtherChar
#  ;

sub shared_literal {
	my $position = $pos;
	if (curr() eq "\\a") {		# bellchar
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "\\e") {	# escapechar
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "\\f") {	# formfeed
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "\\n") {	# newline
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "\\r") {	# carriagereturn
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "\\t") {	# tab
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "\\x") {	# hexchar
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "\\") {	# quoted
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "\\Q") {	# blockquoted
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "{") {		# openbrace
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "}") {		# closebrace
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq ",") {		# comma
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "-") {		# hyphen
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "<") {		# lessthan
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq ">") {		# greaterthan
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "'") {		# singlequote
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "_") {		# underscore
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq ":") {		# colon
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "#") {		# hash
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "=") {		# equal
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "!") {		# exclamation
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	elsif (curr() eq "&") {		# ampersand
		advance();
		return {type => "shared-literal", value => "bellchar"}
	}
	if (my $octal_char = octal_char()) {	# octal_char
		return {type => "shared-literal", value => "bellchar"}
	}
	else {
		$pos = $position;
	}
	if (my $letter = letter()) {	# letter
		return {type => "shared-literal", value => "bellchar"}
	}
	else {
		$pos = $position;
	}
	if (my $digit = digit()) {		# digit
		return {type => "shared-literal", value => "bellchar"}
	}
	else {
		$pos = $position;
	}
	my $other_char = curr();		# otherchar
	advance();
	return { type => "shared_literal", value => $other_char }
# 	return { type => "OtherChar", value => $other_char}
}

# number
#  : digits
#  ;

sub number {
	my $digits = digits();
	return {}
}

# octal_char
#  : ( '\\' ('0' | '1' | '2' | '3') octal_digit octal_digit
#    | '\\' octal_digit octal_digit                     
#    )
#  ;

# TO REWORK --> if ( '0' | '1' | '2' | '3' ) match, then octal_digit can also match
sub octal_char {
	my $octal_digit_1;
	my $octal_digit_2;
	my $position;
	take("\\");
	if (curr() eq "0") {
		advance();
		$octal_digit_1 = octal_digit();
		$octal_digit_2 = octal_digit();
		return {}
	}
	elsif (curr() eq "1") {
		advance();
		$octal_digit_1 = octal_digit();
		$octal_digit_2 = octal_digit();
		return {}
	}
	elsif (curr() eq "2") {
		advance();
		$octal_digit_1 = octal_digit();
		$octal_digit_2 = octal_digit();
		return {}
	}
	elsif (curr() eq "3") {
		advance();
		$octal_digit_1 = octal_digit();
		$octal_digit_2 = octal_digit();
		return {}
	}
	else {
		$octal_digit_1 = octal_digit();
		$octal_digit_2 = octal_digit();
		return {}
	}
}


# octal_digit
#  : '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7'
#  ;


sub octal_digit {
	if (curr() eq "0") {
		take("0");
		return { type => "digit", value => "0" }
	}
	elsif (curr() eq "1") {
		take("1");
		return { type => "digit", value => "1" }
	}
	elsif (curr() eq "2") {
		take("2");
		return { type => "digit", value => "2" }
	}
	elsif (curr() eq "3") {
		take("3");
		return { type => "digit", value => "3" }
	}
	elsif (curr() eq "4") {
		take("4");
		return { type => "digit", value => "4" }
	}
	elsif (curr() eq "5") {
		take("5");
		return { type => "digit", value => "5" }
	}
	elsif (curr() eq "6") {
		take("6");
		return { type => "digit", value => "6" }
	}
	elsif (curr() eq "7") {
		take("7");
		return { type => "digit", value => "7" }
	}
}

 
# digits
#  : digit+
#  ;

sub digits {
	my $position = $pos;
	my @digit;
	while (my $digit = digit()) {
		$position = $pos;
		push @digit, $digit;
	}
	$pos = $position;
	if (@digit >= 1) {
		return { type => "digits", value => \@digit}
	}
}

# digit
#  : '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
#  ;

sub digit {
	if (curr() eq "0") {
		take("0");
		return { type => "digit", value => "0" }
	}
	elsif (curr() eq "1") {
		take("1");
		return { type => "digit", value => "1" }
	}
	elsif (curr() eq "2") {
		take("2");
		return { type => "digit", value => "2" }
	}
	elsif (curr() eq "3") {
		take("3");
		return { type => "digit", value => "3" }
	}
	elsif (curr() eq "4") {
		take("4");
		return { type => "digit", value => "4" }
	}
	elsif (curr() eq "5") {
		take("5");
		return { type => "digit", value => "5" }
	}
	elsif (curr() eq "6") {
		take("6");
		return { type => "digit", value => "6" }
	}
	elsif (curr() eq "7") {
		take("7");
		return { type => "digit", value => "7" }
	}
	elsif (curr() eq "8") {
		take("8");
		return { type => "digit", value => "8" }
	}
	elsif (curr() eq "9") {
		take("9");
		return { type => "digit", value => "9" }
	}
	else {
		return 0;
	}
}

# name
#  : alpha_nums
#  ;

sub name {
	my $alpha_nums = alpha_nums();
	return { type => "name", value => $alpha_nums}
}

# alpha_nums
#  : (letter | '_') (letter | '_' | digit)*
#  ;

sub alpha_nums {
	my $position = $pos;
	my @position = $pos;
	if (curr() eq "_") {
		take("_");
	}
	else {
		my $letter = letter();
	}
}
 
# non_close_parens
#  : non_close_paren+
#  ;

sub non_close_parens {
}

# non_close_paren
#  : ~')' \\ ~CloseParen
#  ;
 
sub non_close_paren {
	my $non_close_paren;
	if (curr() ne ")") {
		$non_close_paren = curr();
		advance();
		return { type => "non_close_paren", value => $non_close_paren };
	}
}

# letter
#  : 'a' | 'b' | 'c' | 'd' | 'e' | 'f' | 'g' | 'h' | 'i' | 'j' | 'k' | 'l' | 'm' | 'n' | 'o' | 'p' | 'q' | 'r' | 's' | 't' | 'u' | 'v' | 'w' | 'x' | 'y' | 'z' |
#   'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G' | 'H' | 'I' | 'J' | 'K' | 'L' | 'M' | 'N' | 'O' | 'P' | 'Q' | 'R' | 'S' | 'T' | 'U' | 'V' | 'W' | 'X' | 'Y' | 'Z'
#  ;

sub letter {
	if (curr() eq "a") {
		take("a");
		return { type => "letter", value => "a"};
	}
	elsif (curr() eq "b") {
		take("b");
		return { type => "letter", value => "b"};
	}
	elsif (curr() eq "c") {
		take("c");
		return { type => "letter", value => "c"};
	}
	elsif (curr() eq "d") {
		take("d");
		return { type => "letter", value => "d"};
	}
	elsif (curr() eq "e") {
		take("e");
		return { type => "letter", value => "e"};
	}
	elsif (curr() eq "f") {
		take("f");
		return { type => "letter", value => "f"};
	}
	elsif (curr() eq "g") {
		take("g");
		return { type => "letter", value => "g"};
	}
	elsif (curr() eq "h") {
		take("h");
		return { type => "letter", value => "h"};
	}
	elsif (curr() eq "i") {
		take("i");
		return { type => "letter", value => "i"};
	}
	elsif (curr() eq "j") {
		take("j");
		return { type => "letter", value => "j"};
	}
	elsif (curr() eq "k") {
		take("k");
		return { type => "letter", value => "k"};
	}
	elsif (curr() eq "l") {
		take("l");
		return { type => "letter", value => "l"};
	}
	elsif (curr() eq "m") {
		take("m");
		return { type => "letter", value => "m"};
	}
	elsif (curr() eq "n") {
		take("n");
		return { type => "letter", value => "n"};
	}
	elsif (curr() eq "o") {
		take("o");
		return { type => "letter", value => "o"};
	}
	elsif (curr() eq "p") {
		take("p");
		return { type => "letter", value => "p"};
	}
	elsif (curr() eq "q") {
		take("q");
		return { type => "letter", value => "q"};
	}
	elsif (curr() eq "r") {
		take("r");
		return { type => "letter", value => "r"};
	}
	elsif (curr() eq "s") {
		take("s");
		return { type => "letter", value => "s"};
	}
	elsif (curr() eq "t") {
		take("t");
		return { type => "letter", value => "t"};
	}
	elsif (curr() eq "u") {
		take("u");
		return { type => "letter", value => "u"};
	}
	elsif (curr() eq "v") {
		take("v");
		return { type => "letter", value => "v"};
	}
	elsif (curr() eq "w") {
		take("w");
		return { type => "letter", value => "w"};
	}
	elsif (curr() eq "x") {
		take("x");
		return { type => "letter", value => "x"};
	}
	elsif (curr() eq "y") {
		take("y");
		return { type => "letter", value => "y"};
	}
	elsif (curr() eq "z") {
		take("z");
		return { type => "letter", value => "z"};
	}
	elsif (curr() eq "A") {
		take("A");
		return { type => "letter", value => "A"};
	}
	elsif (curr() eq "B") {
		take("B");
		return { type => "letter", value => "B"};
	}
	elsif (curr() eq "C") {
		take("C");
		return { type => "letter", value => "C"};
	}
	elsif (curr() eq "D") {
		take("D");
		return { type => "letter", value => "D"};
	}
	elsif (curr() eq "E") {
		take("E");
		return { type => "letter", value => "E"};
	}
	elsif (curr() eq "F") {
		take("F");
		return { type => "letter", value => "F"};
	}
	elsif (curr() eq "G") {
		take("G");
		return { type => "letter", value => "G"};
	}
	elsif (curr() eq "H") {
		take("H");
		return { type => "letter", value => "H"};
	}
	elsif (curr() eq "I") {
		take("I");
		return { type => "letter", value => "I"};
	}
	elsif (curr() eq "J") {
		take("J");
		return { type => "letter", value => "J"};
	}
	elsif (curr() eq "K") {
		take("K");
		return { type => "letter", value => "K"};
	}
	elsif (curr() eq "L") {
		take("L");
		return { type => "letter", value => "L"};
	}
	elsif (curr() eq "M") {
		take("M");
		return { type => "letter", value => "M"};
	}
	elsif (curr() eq "N") {
		take("N");
		return { type => "letter", value => "N"};
	}
	elsif (curr() eq "O") {
		take("O");
		return { type => "letter", value => "O"};
	}
	elsif (curr() eq "P") {
		take("P");
		return { type => "letter", value => "P"};
	}
	elsif (curr() eq "Q") {
		take("Q");
		return { type => "letter", value => "Q"};
	}
	elsif (curr() eq "R") {
		take("R");
		return { type => "letter", value => "R"};
	}
	elsif (curr() eq "S") {
		take("S");
		return { type => "letter", value => "S"};
	}
	elsif (curr() eq "T") {
		take("T");
		return { type => "letter", value => "T"};
	}
	elsif (curr() eq "U") {
		take("U");
		return { type => "letter", value => "U"};
	}
	elsif (curr() eq "V") {
		take("V");
		return { type => "letter", value => "V"};
	}
	elsif (curr() eq "W") {
		take("W");
		return { type => "letter", value => "W"};
	}
	elsif (curr() eq "X") {
		take("X");
		return { type => "letter", value => "X"};
	}
	elsif (curr() eq "Y") {
		take("Y");
		return { type => "letter", value => "Y"};
	}
	elsif (curr() eq "Z") {
		take("Z");
		return { type => "letter", value => "Z"};
	}
}

# QUOTING
#
#         \x         where x is non-alphanumeric is a literal x
#         \Q...\E    treat enclosed characters as literal
# Quoted      : '\\' NonAlphaNumeric;
# BlockQuoted : '\\Q' .*? '\\E';

# CHARACTERS
#
#         \a         alarm, that is, the BEL character (hex 07)
#         \cx        "control-x", where x is any ASCII character
#         \e         escape (hex 1B)
#         \f         form feed (hex 0C)
#         \n         newline (hex 0A)
#         \r         carriage return (hex 0D)
#         \t         tab (hex 09)
#         \ddd       character with octal code ddd, or backreference
#         \xhh       character with hex code hh
#         \x{hhh..}  character with hex code hhh..
# BellChar       : '\\a';
# ControlChar    : '\\c';
# EscapeChar     : '\\e';
# FormFeed       : '\\f';
# NewLine        : '\\n';
# CarriageReturn : '\\r';
# Tab            : '\\t';
# Backslash      : '\\';
# HexChar        : '\\x' ( HexDigit HexDigit
#                        | '{' HexDigit HexDigit HexDigit+ '}'
#                        )
#                ;

# CHARACTER TYPES
#
#         .          any character except newline;
#                      in dotall mode, any character whatsoever
#         \C         one data unit, even in UTF mode (best avoided)
#         \d         a decimal digit
#         \D         a character that is not a decimal digit
#         \h         a horizontal white space character
#         \H         a character that is not a horizontal white space character
#         \N         a character that is not a newline
#         \p{xx}     a character with the xx property
#         \P{xx}     a character without the xx property
#         \R         a newline sequence
#         \s         a white space character
#         \S         a character that is not a white space character
#         \v         a vertical white space character
#         \V         a character that is not a vertical white space character
#         \w         a "word" character
#         \W         a "non-word" character
#         \X         an extended Unicode sequence
#
#       In  PCRE,  by  default, \d, \D, \s, \S, \w, and \W recognize only ASCII
#       characters, even in a UTF mode. However, this can be changed by setting
#       the PCRE_UCP option.
# Dot                     : '.';
# OneDataUnit             : '\\C';
# DecimalDigit            : '\\d';
# NotDecimalDigit         : '\\D';
# HorizontalWhiteSpace    : '\\h';
# NotHorizontalWhiteSpace : '\\H';
# NotNewLine              : '\\N';
# CharWithProperty        : '\\p{' UnderscoreAlphaNumerics '}';
# CharWithoutProperty     : '\\P{' UnderscoreAlphaNumerics '}';
# NewLineSequence         : '\\R';
# WhiteSpace              : '\\s';
# NotWhiteSpace           : '\\S';
# VerticalWhiteSpace      : '\\v';
# NotVerticalWhiteSpace   : '\\V';
# WordChar                : '\\w';
# NotWordChar             : '\\W';
# ExtendedUnicodeChar     : '\\X';

# CHARACTER CLASSES
#
#         [...]       positive character class
#         [^...]      negative character class
#         [x-y]       range (can be used for hex characters)
#         [[:xxx:]]   positive POSIX named set
#         [[:^xxx:]]  negative POSIX named set
#
#         alnum       alphanumeric
#         alpha       alphabetic
#         ascii       0-127
#         blank       space or tab
#         cntrl       control character
#         digit       decimal digit
#         graph       printing, excluding space
#         lower       lower case letter
#         print       printing, including space
#         punct       printing, excluding alphanumeric
#         space       white space
#         upper       upper case letter
#         word        same as \w
#         xdigit      hexadecimal digit
# #
#       In PCRE, POSIX character set names recognize only ASCII  characters  by
#       default,  but  some  of them use Unicode properties if PCRE_UCP is set.
#       You can use \Q...\E inside a character class.
# CharacterClassStart  : '[';
# CharacterClassEnd    : ']';
# Caret                : '^';
# Hyphen               : '-';
# POSIXNamedSet        : '[[:' AlphaNumerics ':]]';
# POSIXNegatedNamedSet : '[[:^' AlphaNumerics ':]]';

# QuestionMark : '?';
# Plus         : '+';
# Star         : '*';
# OpenBrace    : '{';
# CloseBrace   : '}';
# Comma        : ',';

# ANCHORS AND SIMPLE ASSERTIONS
#
#         \b          word boundary
#         \B          not a word boundary
#         ^           start of subject
#                      also after internal newline in multiline mode
#         \A          start of subject
#         $           end of subject
#                      also before newline at end of subject
#                      also before internal newline in multiline mode
#         \Z          end of subject
#                      also before newline at end of subject
#         \z          end of subject
#         \G          first matching position in subject
# WordBoundary                   : '\\b';
# NonWordBoundary                : '\\B';
# StartOfSubject                 : '\\A'; 
# EndOfSubjectOrLine             : '$';
# EndOfSubjectOrLineEndOfSubject : '\\Z'; 
# EndOfSubject                   : '\\z'; 
# PreviousMatchInSubject         : '\\G';

# MATCH POINT RESET
#
#         \K          reset start of match
# ResetStartMatch : '\\K';

# SubroutineOrNamedReferenceStartG : '\\g';
# NamedReferenceStartK             : '\\k';

# Pipe        : '|';
# OpenParen   : '(';
# CloseParen  : ')';
# LessThan    : '<';
# GreaterThan : '>';
# SingleQuote : '\'';
# Underscore  : '_';
# Colon       : ':';
# Hash        : '#';
# Equals      : '=';
# Exclamation : '!';
# Ampersand   : '&';

# OtherChar : . ;

# fragments
# fragment UnderscoreAlphaNumerics : ('_' | AlphaNumeric)+;
# fragment AlphaNumerics           : AlphaNumeric+;
# fragment AlphaNumeric            : [a-zA-Z0-9];
# fragment NonAlphaNumeric         : ~[a-zA-Z0-9];
# fragment HexDigit                : [0-9a-fA-F];
# fragment ASCII                   : [\u0000-\u007F];






__END__

# '\\';

# '\\a';
# '\\c';
# '\\e';
# '\\f';
# '\\n';
# '\\r';
# '\\t';
# '\\x'
# '\\C';
# '\\d';
# '\\D';
# '\\h';
# '\\H';
# '\\N';
# '\\p{'
# '\\P{'
# '\\R';
# '\\s';
# '\\S';
# '\\v';
# '\\V';
# '\\w';
# '\\W';
# '\\X';
# '\\g'
# '\\k'
# '\\C'
# '\\X'
# '\\Q'
# '\\E'
# '\\b'
# '\\B'
# '\\A'
# '\\Z'
# '\\z'
# '\\G'
# '\\K'
# \n              reference by number (can be ambiguous)



