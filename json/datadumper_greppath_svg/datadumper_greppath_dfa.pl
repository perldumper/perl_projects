#!/usr/bin/perl

# perl -Mdd -le 'use JSON; $file=<>;$text=decode_json($file); dd $text' avril.json | ./datadumper_greppath_dfa.pl

use strict;
use warnings;
# no warnings "utf8";
# binmode STDIN,  ":utf8";
# binmode STDOUT, ":utf8";
# binmode STDERR, ":utf8";
# alternative to the -CA flag. Allows for unicode characters in @ARGV, in case the name of the file contains ones
use Encode qw(decode);
# use Regexp::Debugger;
# @ARGV = map { decode "UTF-8", $_ } @ARGV;


# BOLD RED like grep(1)
use constant   RESET => "\e[0m";
use constant    BOLD => "\e[1m";
use constant   BLACK => "\e[30m";
use constant     RED => "\e[31m";
# RED, YELLOW and GREEN for malformed json, like perl6
use constant   GREEN => "\e[32m";
use constant  YELLOW => "\e[33m";
use constant    BLUE => "\e[34m";
use constant MAGENTA => "\e[35m";
use constant    CYAN => "\e[36m";
use constant  BRIGHT_YELLOW => "\e[93m";

my $json;
my $jq_output = 0;
$/=undef;

sub usage {
print STDERR <<"USAGE";
  usage :        json_greppath FILE [jq] [-i] [not] [and|or] [--] [PATTERNS]
      cat FILE | json_greppath      [jq] [-i] [not] [and|or] [--] [PATTERNS]
USAGE
}

sub help {
print STDERR <<"HELP";
  usage :        datadumper_greppath FILE [jq] [-i] [not] [and|or] [--] [PATTERNS]
      cat FILE | datadumper_greppath      [jq] [-i] [not] [and|or] [--] [PATTERNS]

  jq           output suitable for the jq CLI utility
  -i           case insensitive
  not          selection is inversed
  and          all PATTERNS must found a match among the keys, indexes and the terminal value of a single "path"
  or           any PATTERN  must found a match among the keys, indexes and the terminal value of a single "path"
  --           after '--', everything is interpreted as PATTERNS
  PATTERN      Perl regular expresion. Quotes are sometime required to avoid shell interpolation,
               and metacharacters must be escaped if they should match literally
HELP
}

if (@ARGV) {

	if (-e $ARGV[0]) { local @ARGV = shift; $json = <ARGV>   }
# 	if (-e $ARGV[0]) { open FH, "<:utf8", $ARGV[0]; $json = <FH>; close FH; shift; }
# 	if (-e $ARGV[0]) { open FH, "<:utf8", $ARGV[0]; $json = <FH>; $json = decode "UTF-8", $json; close FH; shift; }
	elsif ($ARGV[0] =~ /^(?:-{0,2}h|-{0,2}help)$/) {
		help(); exit
	}
# 	else { $json = shift }	# if reading json from STDIN and patterns specified, does not work
							# first test not -t STDIN, then tests if @ARGV > 0 ??
}
elsif (not -t STDIN) { $json = <STDIN>  }	# if json from STDIN and patterns in @ARGV, does not work
# if (not -t STDIN) { $json = <STDIN>  }	# if json from STDIN and patterns in @ARGV, does not work
else { usage(); exit }

if (@ARGV) {
	if ($ARGV[0] =~ /^-{0,2}jq$/ ) { $jq_output = 1; shift }
}
# print "HERE";
# print "ARGV \"@ARGV\"";
# print "JSON $json\n";

# tokenizer
my $end = 0;
my @tokens;

while (not $end){

	if    ($json =~ m/\G  \{    /gcx)  { push @tokens,  { type => "curly_open",     value => "{"     } }
	elsif ($json =~ m/\G  \}    /gcx)  { push @tokens,  { type => "curly_close",    value => "}"     } }
	elsif ($json =~ m/\G  \[    /gcx)  { push @tokens,  { type => "square_open",    value => "["     } }
	elsif ($json =~ m/\G  \]    /gcx)  { push @tokens,  { type => "square_close",   value => "]"     } }
	elsif ($json =~ m/\G   ,    /gcx)  { push @tokens,  { type => "comma",          value => ","     } }
	elsif ($json =~ m/\G   =>   /gcx)  { push @tokens,  { type => "fatcomma",       value => "=>"    } }
	elsif ($json =~ m/\G   =    /gcx)  { push @tokens,  { type => "equal",          value => "="     } }
	elsif ($json =~ m/\G  undef /gcx)  { push @tokens,  { type => "undef",          value => "undef" } }
	elsif ($json =~ m/\G  True  /gcx)  { push @tokens,  { type => "true",           value => "true"  } }
	elsif ($json =~ m/\G  False /gcx)  { push @tokens,  { type => "false",          value => "false" } }
	elsif ($json =~ m/\G   ;    /gcx)  { push @tokens,  { type => "semicolon",      value => ";"     } }

# 	elsif ($json =~ m/\G[ \n\r\t]+/gc) { 1; }	# more laxed version of whitespace than specification
					# allows the tokenizing of multiple JSON in a single file and separated by newlines
	elsif ($json =~ m/\G\s++/gc) { 1; }

	#-----------------------------------------------------------------------------

	# single quoted string / number
	elsif ($json =~ m@\G ' ( (?:[^\\']|\\.)* ) ' @gcx) { push @tokens, { type => "string", value => $1 } }

	# double quoted string / number
	elsif ($json =~ m@\G " ( (?:[^\\"]|\\.)* ) " @gcx) { push @tokens, { type => "string", value => $1 } }

	#-----------------------------------------------------------------------------
	elsif ($json =~ m/\G( [-+]? \d+ (?: \. \d+ )? ) /gcx) { push @tokens, { type => "number", value => $1 } }
	#-----------------------------------------------------------------------------

	# perl -MRegexp::Common="balanced" -le 'print $RE{balanced}{-parens=>"()"}'
	# blessed reference / object
# 	elsif ($json =~ m/\G(bless ( (?:\((?:(?>[^\(\)]++)|(?-1))*\)) )? ) /gcx) { push @tokens, { type => "bless", value => $1 }  }

	elsif ($json =~ m/\Gbless \s*+ \( /gcx) { push @tokens, { type => "bless", value => "bless(" }  }

	elsif ($json =~ m/\G ( \$[a-zA-Z_][a-zA-Z0-9_]*+ ->(?:{' (?:[^\\']|\\.)* '}|\[\d+\]|->)++ ) /gcx) {

			push @tokens, { type => "reference", value => $1 }
	}
	elsif ($json =~ m/\G ( \$[a-zA-Z_][a-zA-Z0-9_]*+) /gcx)  { push @tokens,  { type => "variable", value => $1 } }

	elsif ($json =~ m/\G  \)   /gcx)  { push @tokens,  { type => "paren_close",    value => ")"   } }
# 	elsif ($json =~ m/\Gdo\{ \\ \( /gcx) { push @tokens, { type => "", value => "" } }

	else { $end = 1 }
}

$,="\n";
$\="\n";

$_->{value} =~ s/\n/\\n/g for @tokens;	# wasteful, only need it on string tokens, do it inside the tokenizer
$_->{value} =~ s/\r/\\r/g for @tokens;
$_->{value} =~ s/\t/\\t/g for @tokens;

print "$_->{type}\t$_->{value}" for @tokens;
exit;

my @stack; # stack-based tree walking (pushdown automata ?)
my $bless_level = 0;
my @paths;
my @indexes;
my ($token,$value);
my $container;

my $initial_state = "root";
# my $initial_state = "variable";
my $state = $initial_state;
# our $state = $initial_state;
our @container_stack; 	# keep track of if we are inside an object or inside an array
our $i;
my %state_transition;
my %state_transition_subroutine;

my $object_opening = sub {
# 	print "SUB object_opening\n";
	if (@container_stack) {
# 		print "PUSH\n";
		push @stack, {type => "index", value => $indexes[-1]} if $container_stack[-1] eq "array";
	}
	push @container_stack, "object";

	if ($tokens[$i+1]->{type} eq "curly_close") {  # empty object			# UNINITIALIZED VALUE
		push @paths, [ @stack, { type => "empty", value => "{}" } ];	# PRINT HERE
	}
};


my $object_closing = sub {
# 	print "SUB object_closing\n";
	if (@container_stack >= 2) {
		$indexes[-1]++ if $container_stack[-2] eq "array";
	}
	pop @container_stack;
	pop @stack;		# if $container_stack[-1] eq "object" delete key, elsif eq "array" delete index

# 	if (not defined $container_stack[-1]) {
# 		print "UNDEFINED";
# 	}

	if (@container_stack) {
	if ($container_stack[-1] eq "bless") {
		if ($tokens[$i+1]->{value} eq ",") {
			$i++;
			if ($tokens[$i+1]->{type} eq "string") {	# class / package of blessed hash
				$i++;
				if ($tokens[$i+1]->{value} eq ")") {
					$i++;
					pop @container_stack;
				}
				else { die "no closing paren found found\n"; }
			}
			else { die "no package found\n"; }
		}
		else { die "no comma found\n"; }
	}
	}
# 	if (@container_stack == 0) {
	else {
		# in case there are several json objects one after the other in the same file
# 		print "\@container_stack == 0 STATE \"$state\" NEWSTATE \"$state_transition{$state}->{end}\"";
		$state = $state_transition{$state}->{end};	# root
	}
};

my $array_opening = sub {
# 	print "SUB array_opening\n";
	if (@container_stack) {
		push @stack, {type => "index", value => $indexes[-1]} if $container_stack[-1] eq "array";
	}
	push @container_stack, "array";

	if (@indexes) { push @indexes, 0 }
	else          { $indexes[0]  = 0 }

	if ($tokens[$i+1]->{type} eq "square_close") {  # empty array			# UNINITIALIZED VALUE
		push @paths, [ @stack, { type => "empty", value => "[]" } ];	# PRINT HERE
	}
};


my $array_closing = sub {
# 	print "SUB array_closing\n";
	pop @indexes;
	if (@container_stack >= 2) {
		$indexes[-1]++ if $container_stack[-2] eq "array";
	}
	pop @container_stack;
	if ($container_stack[-1] eq "object") {
		pop @stack;		# delete key             key => [ arrary ]
	}
	if (@container_stack) {
	if ($container_stack[-1] eq "bless") {
		if ($tokens[$i+1]->{value} eq ",") {
			$i++;
			if ($tokens[$i+1]->{type} eq "string") {	# class / package of blessed hash
				$i++;
				if ($tokens[$i+1]->{value} eq ")") {
					$i++;
					pop @container_stack;
				}
				else { die "no closing paren found found\n"; }
			}
			else { die "no package found\n"; }
		}
		else { die "no comma found\n"; }
	}
	}
# 	if (@container_stack == 0) {
	else {
		# in case there are several json objects one after the other in the same file
		$state = $state_transition{$state}->{end};	# root
	}
};

my $object_value = sub {
# 	print "SUB object_value\n";
	my ($value, $type) = @_;

	if (@container_stack) {
		if ($container_stack[-1] eq "array") {
			push @stack, {type => "index", value => $indexes[-1]};
			$indexes[-1]++;
		}
	}
	push @stack, {type => $type, value => $value};
	push @paths, [@stack];								# PRINT HERE
	pop @stack;		# delete terminal value
	pop @stack;		# delete key

};

my $array_value = sub {
# 	print "SUB array_value\n";
	my ($value, $type) = @_;

	if (@container_stack) {
		if ($container_stack[-1] eq "array") {
			push @stack, {type => "index", value => $indexes[-1]};
			$indexes[-1]++;
		}
	}
	push @stack, {type => $type, value => $value};
	push @paths, [@stack];								# PRINT HERE
	pop @stack;		# delete terminal value
	pop @stack;		# delete current index
};

my $key = sub {
# 	print "SUB key\n";
	my $value = shift;
	push @stack, { type => "key", value => $value };
# 	print "PUSH\n";
	$token = $token;
};

my $comma = sub {
	if ($container_stack[-1] eq "array") {
# 		$token = "array_comma";
		$state = "array_comma";
	}
	elsif ($container_stack[-1] eq "object") {
# 		$token = "object_comma";
		$state = "object_comma";
	}
};

my $bless = sub {
	push @container_stack, "bless";
};

my $paren_close = sub {
	if ($container_stack[-1] eq "bless") {
		pop @container_stack, "array";
	}
};

# my $no_op = sub {
# 	return;
# };


# root --> variable_definition+

# variable_definition --> \$[a-zA-Z_][a-zA-Z0-9_]* = (?: hash | array | object )



%state_transition = (

			# before first token or after end of outter most container
			root => { variable => "variable",
						semicolon => "root"
					},
			# after variable token
           variable => {
						equal => "equal",
					},

			# after '=' token
	          equal => {   curly_open => "object_opening",
                          square_open => "array_opening",
                           bless => "bless",
					},

	          bless => {   curly_open => "object_opening",
                          square_open => "array_opening",
					},

	# after '{' token
	object_opening => {       string => "key",
                         curly_close => "object_closing",
					},

	# after '[' token
	 array_opening => {       string => "array_value",
                              number => "array_value",
                                true => "array_value",
                               false => "array_value",
                               undef => "array_value",
                               bless => "array_value",
                           reference => "array_value",
                         square_open => "array_opening",
                        square_close => "array_closing",
                          curly_open => "object_opening",
					},

		# after string token
	           key => {     fatcomma => "fatcomma",
					},

	# after '=>' token
	      fatcomma => {       string => "object_value",
                              number => "object_value",
                                true => "object_value",
                               false => "object_value",
                               undef => "object_value",
                               bless => "object_value",
                           reference => "object_value",
                         square_open => "array_opening",
                          curly_open => "object_opening",
					},

	# after one of the object_values, while inside an object container
# 	  object_value => { object_comma => "object_comma",
	  object_value => {        comma => "comma",
                         curly_close => "object_closing",
					},

	# after one of the array_values, while inside an array container
# 	   array_value => {  array_comma => "array_comma",
	   array_value => {        comma => "comma",
                        square_close => "array_closing",
					},

	# after ',' token
	  object_comma => {       string => "key",
					},

	# after ',' token
	   array_comma => {       string => "array_value",
                              number => "array_value",
                                true => "array_value",
                               false => "array_value",
                                null => "array_value",
                           reference => "array_value",
                         square_open => "array_opening",
                          curly_open => "object_opening",
					},

	# after '}' token
	object_closing => { object_comma => "object_comma",
                         array_comma => "array_comma",
                         curly_close => "object_closing",
                        square_close => "array_closing",
                                 end => "root",
#                            semicolon => "semicolon",
					},

	# after ']' token
	 array_closing => { object_comma => "object_comma",
                         array_comma => "array_comma",
                         curly_close => "object_closing",
                        square_close => "array_closing",
                                 end => "root",
#                            semicolon => "semicolon",
					},
	# after ';' token
    semicolon => { end => "root"  }
);




%state_transition_subroutine = (

	object_opening => $object_opening,
	array_opening  => $array_opening,
	key            => $key,
	object_value   => $object_value,
	array_value    => $array_value,
	object_closing => $object_closing,
	array_closing  => $array_closing,
	comma          => $comma,
	object_comma   => sub { },
	array_comma    => sub { },
	root           => sub { },
	variable       => sub { },
	equal          => sub { },
	fatcomma       => sub { },
	semicolon      => sub { },
	bless          => $bless,
	paren_close    => $paren_close,
);



for ($i=0; $i < @tokens; $i++) {

	($token, $value) = ( $tokens[$i]->{type}, $tokens[$i]->{value} );
	
	# export this inside the subroutine of comma which would decide if it is an array_comma or object comma
	# and then call
	# $state_transition_subroutine{$state}->($value, $token);

	if ($token eq "comma") {
# 		print "COMMA";
		if ($container_stack[-1] eq "array") {
			$token = "array_comma";
		}
		elsif ($container_stack[-1] eq "object") {
			$token = "object_comma";
		}
	}

# 	if (not exists $state_transition{$state}->{$token}) {
# 		die " Malformed json file\n \"$token\" is not an allowed input when in the state \"$state\"\n";
# 	}
# 
# 	if (not exists $state_transition{$state}) {
# 		print "\$state \"$state\" does not exists\n";
# 	}
# 
	print "\nTOKEN $token VALUE $value";
	print "BEFORE $state";


	my $state_before = $state;

	if (defined $state) {
		print "STATE $state";
	}
	else {
		print "STATE undefined";
	}
	$state = $state_transition{$state}->{$token};
	if (defined $state) {
		print "AFTER $state";
	}
	else {
		print "AFTER undefined";
	}

# 	print "AFTER $state\n";

# 	print "STACK\n";
# 	foreach (@stack) {
# 		if (not defined $_->{token}) {
# 			print "token undefined\n";
# 		}
# 		if (not defined $_->{value}) {
# 			print "value undefined\n";
# 		}
# 		print "tok $_->{token} val $_->{value}\n" if defined $_->{token} and defined $_->{value}
# 	}
# 
# 	print "CALLING $state\n";
	$state_transition_subroutine{$state}->($value, $token);		# CORRECT

# 	print "=" x 40, "\n";

	# put this inside array_closing and inside object_closing ??
	if (@container_stack == 0) {
# 		print "CONTAINER STACK == 0";
# 		print "\nBEFORE $state_before\n";	# object_value
# 		print "AFTER $state\n";			# object_closing
# 		# in case there are several json objects one after the other in the same file
# 		$state = $state_transition{$state}->{"end"};	# root
# 		print "AFTER $state\n";			# root
# 		print "STATE $state\n";			# root
	}

# 	$state_transition_subroutine{$state}->($value, $token);		# TEST
}
# $state = $state_transition{$state}->{"end"};

unless ($state eq "root") {
	die " Malformed json file\n \"$state\" is not an accepting state\n";
}

# exit;


my @path;
my @keys_and_values;	# allows regex_patterns to match individual keys/index/terminal values
						# and not in the entire string of one path.       example:  ^format$

# PREPARE THE PATH INFORMATION SO THAT IT IS SUITABLE BOTH FOR SEARCHING AND FOR PRETTY PRINTED OUTPUT

foreach my $branch (@paths) {
	@path = ();
	push @keys_and_values, [];

	for (my $i=0; $i < $branch->$#*; $i++) {		# processing terminal value below
		$_ = $branch->[$i];

		if ( $_->{type} eq "key") {					# STRING OF A KEY
			push $keys_and_values[-1]->@*,  $_;
		}
		elsif ( $_->{type} eq "index") {			# INDEX
			push $keys_and_values[-1]->@*,  $_;
		}
	}

	push $keys_and_values[-1]->@*,  $branch->[-1];  # STRING TERMINAL VALUE
}


sub reduce_and {
	foreach (@_) {
		return 0 if $_ == 0;
	}
	return 1;
}

sub reduce_or {
	foreach (@_) {
		return 1 if $_ == 1;
	}
	return 0;
}

sub print_grep_color {
	my $json_paths_to_grep = shift;								# need for it disappear
	my $patterns = shift;										# need for it disappear
	my $logic = shift;				# and / or					# need for it disappear
	my $not = shift;				# negative					# need for it disappear
# 	my $case_insensitive = shift;	# case insensitive or not	# need for it disappear
	our $case_insensitive = shift;	# case insensitive or not	# need for it disappear
	my $color = shift;											# need for it disappear
	my $current_color;											# need it ?

	my @pos;
	my @pos_pat;
	my $have_pattern_matched;
	my $flip_flop = "0" x length $key;
	my $flip_flop_pat;

	my $path;
	my $pat;
	my $key;
	my $line;
	my $i;
	my $j;
	local $\="";
	local $,="";	

	# FOR EACH PATH
	while ($path = shift $json_paths_to_grep->@*) {					# loop disappear
		$have_pattern_matched->%* = map { $_ => 0 } $patterns->@*;

		if ($jq_output) { $line = "" } else { $line = "->" }

		# FOR EACH KEY or INDEX, plus the TERMINAL VALUE
		for ($j=0; $j < $path->@*; $j++) {
			$key = $path->[$j]->{value};	# key / index / terminal value of the path

			# FROM THE ARRAY OF POSITIONS OF MATCHES OF EACH PATTERN
			# OBTAIN THE OVERLAPPING ARRAY OF POSITIONS,
			# SO THE MATCHES CAN BE COLORED IN RED

			# START MATCH_SUBSTRING_POSITIONS (inline faster that encapsulated in a function)
			foreach my $pat ($patterns->@*) {
				@pos_pat = ();
				$flip_flop_pat = "0" x length $key;

				if ($case_insensitive) {
					while ($key =~ /($pat)/ig) {				# find positions of all matches in a key/index/terminal value
						push @pos_pat, [$-[0], $+[0]];			# and foreach, push start and end positions
					}
				}
				else {
					while ($key =~ /($pat)/g) {					# find positions of all matches in a key/index/terminal value
						push @pos_pat, [$-[0], $+[0]];			# and foreach, push start and end positions
					}
				}
				foreach (@pos_pat) {
					substr $flip_flop_pat, $_->[0], $_->[1] - $_->[0], "1" x ($_->[1] - $_->[0]);
				}
				$flip_flop = $flip_flop | $flip_flop_pat; # accumulated OVERLAP of match positions over 1 key/index/terminal value

				if (@pos_pat) {		# this pattern match at least once for this key / index / value
					$have_pattern_matched->{$pat} = $have_pattern_matched->{$pat} | 1;	# bitwise-OR, logical-OR doesn't work for this
				}
				else {
					$have_pattern_matched->{$pat} = $have_pattern_matched->{$pat} | 0;
				}
			}

			# get the overlapping start and end positions of substrings that match for all the regex patterns
			# to obtain one flip-flop seqence of match / outside match alternation
			while ($flip_flop =~ /(1+)/g) {
				push @pos, [$-[0], $+[0]];
			}
			# END MATCH_SUBSTRING_POSITIONS

			# PRETTY OUTPUT
			# put double-quotes around strings, { } around object keys and [ ] around array indexes
			if ($path->[$j]->{type} eq "key") {								# key
				if ($jq_output) {
					if ($path->[$j]->{value} =~ /^\d| / ) {
						$line .= ".\""
					}
					else { $line .= "." }
				}
# 				else { $line .= "{\"" }
# 				if ($color) {
# 					$line .= "{" . BOLD . BLUE . "\"";
# 				}
				else {
					if ($color and ! @$patterns) {
# 						$line .= "{\"";
						$line .= "{" . BOLD . BLUE . "\"";
						$current_color = BOLD . BLUE;
					}
					else {
						$line .= "{\"";
					}
				}
			}
			elsif ($path->[$j]->{type} eq "index") {						# array index
				if ($jq_output and $j == 0) {								# root container in an array
					$line .= ".["
				}
				else {
# 					$line .= "["
					if ($color and ! @$patterns) {
# 						$line .= "[" . YELLOW;
						$line .= "[";
						$current_color = "";
					}
					else {
						$line .= "[";
					}
				}
			}
			elsif ($path->[$j]->{type} eq "string") {						# string terminal value
				if ($jq_output) {
					$line .= " --> \"";
				}
				else {
# 					$line .= "\"";
					if ($color and ! @$patterns) {
# 						$line .=  "\"";
						$line .= GREEN . "\"";
						$current_color = GREEN;
					}
					else {
						$line .= "\"";
					}
				}
			}
			elsif ($jq_output) { $line .= " --> " }							# terminal value that is not a string
			else {
				if ($jq_output) { $line .= " --> " }
# 				if ($color and ! @pos) {
				if ($color and ! @$patterns) {
					if ($path->[$j]->{type} eq "null") {
						$line .= BOLD . BLACK;
						$current_color .= BOLD . BLACK;
					}
				}
			}

			# COMPOSE THE LINE. ALTERNANCE OF COLORLESS AND COLORED (segments that match) SUBSTRINGS
			if (@pos and $color) {						# if at least one match in the current line
				$line .= substr $key, 0, $pos[0]->[0];									# before first match COLORLESS

				for($i=0; $i < @pos; $i++) {
					$line .=  BOLD . RED . substr($key, $pos[$i]->[0], $pos[$i]->[1] - $pos[$i]->[0]) . RESET;	# match COLORED
# 					$line .=  BOLD . RED . substr($key, $pos[$i]->[0], $pos[$i]->[1] - $pos[$i]->[0]) . RESET . $current_color;	# match COLORED
					if (defined $pos[$i+1]) {
						$line .=      substr $key, $pos[$i]->[1], $pos[$i+1]->[0] - $pos[$i]->[1];	# in-between matches COLORLESS
					}
				}
				$line .= substr($key, $pos[-1]->[1], length $key);									# after last match COLORLESS
			}
			else {
				$line .= $key;
			}

			# PRETTY OUTPUT
			# put double-quotes around strings, { } around object keys and [ ] around array indexes
			# and separate keys, indexes and values by an arrow ->
			if ($path->[$j]->{type} eq "key") {								# key
# 				if ($color) {
# 					$line .= RESET;
# 				}
				if ($jq_output) {
					if ($path->[$j]->{value} =~ /^\d| / ) {
						$line .= "\""
					}
				}
				else {
# 					$line .= "\"}->";
					if ($color and ! @$patterns) {
						$line .= BOLD . BLUE ."\"" . RESET ."}->";
					}
					else {
						$line .= "\"}->";
					}
				}
			}
			elsif ($path->[$j]->{type} eq "index") {						# array index
				if ($jq_output) {
					$line .= "]"
				}
				else {
# 					$line .= "]->";
					if ($color and ! @$patterns) {
						$line .= RESET ."]->";
					}
					else {
						$line .= "]->";
					}
				}
			}
			elsif ($path->[$j]->{type} eq "string") {						# string terminal value
# 				$line .= "\""
				if ($color and ! @$patterns) {
					$line .= GREEN . "\"" . RESET;
				}
				else {
					$line .= "\"";
				}
			}

		}

		if ($logic eq "or") {
			if ($not) {
				print $line . "\n" unless reduce_or(values $have_pattern_matched->%*);
			}
			else {
				print $line . "\n" if reduce_or(values $have_pattern_matched->%*);
			}
		}
		elsif ($logic eq "and") {
			if ($not) {
				print $line . "\n" unless reduce_and(values $have_pattern_matched->%*);
			}
			else {
				print $line . "\n" if reduce_and(values $have_pattern_matched->%*);
			}
		}
		else {	# "print all" case
			print $line . "\n";
		}
	}
}

my $color;
if (-t STDOUT) { $color = 1 }
else           { $color = 0 }

my $match;
my $all_matches;

unless (@ARGV) {
# 	print_grep_color(\@keys_and_values, [], "print all");
# 	print_grep_color(\@keys_and_values, \@ARGV, $logic, $not, $case_insensitive, $color);
	print_grep_color(\@keys_and_values, [], "print all", "", "", $color);
	exit;
}

my $case_insensitive = 0;		# case sensitive by default
my $logic = "and";				# all patterns have to match by default
my $not = 0;					# do not exclude matching patterns by default

for (1) {
	if ($ARGV[0] eq "-i") {							# INSENSITIVE
		shift;
		$case_insensitive = 1;
		redo;
	}
	if ($ARGV[0] =~ /^\-{0,2}or|^\-{0,2}any/) {		# ANY PATTERN HAVE TO MATCH
		shift;
		$logic = "or";
		redo;
	}
	elsif ($ARGV[0] =~ /^-{0,2}and|^-{0,2}all/) {	# ALL PATTERNS HAVE TO MATCH
		shift;
		$logic = "and";
		redo;
	}
	elsif ($ARGV[0] =~ /^-{0,2}not|^-{0,2}none/) {	# NEGATION
		shift;
		$not = 1;
		redo;
	}
	elsif ($ARGV[0] eq "-c") {						# force color
		shift;
		$color = 1;
		last;
	}
	elsif ($ARGV[0] eq "-C") {						# coloress
		shift;
		$color = 0;
		last;
	}
	elsif ($ARGV[0] eq "--") {						# END OF OPTIONS, START OR REGEXES
		shift;
		last;
	}
}

print_grep_color(\@keys_and_values, \@ARGV, $logic, $not, $case_insensitive, $color);

# print "\nCOLOR \"$color\"\n";





__END__


# OTHER CASES

# $ perl -Mdd -e 'package mypack; package main; dd bless {}, "mypack"'
# $VAR1 = bless( {}, 'mypack' );

# $ perl -Mdd -e 'package mypack; package main; dd bless [], "mypack"'
# $VAR1 = bless( [], 'mypack' );

# $ perl -Mdd -e 'package mypack; package main; $ref=\$var; dd bless $ref, "mypack"'
# $VAR1 = bless( do{\(my $o = undef)}, 'mypack' );

# $ perl -Mdd -e 'package mypack; package main; $var=5; $ref=\$var; dd bless $ref, "mypack"'
# $VAR1 = bless( do{\(my $o = 5)}, 'mypack' );

# $ perl -Mdd -e 'package mypack; package main; $var=[]; $ref=\$var; dd bless $ref, "mypack"'
# $VAR1 = bless( do{\(my $o = [])}, 'mypack' );

# $ perl -Mdd -e 'package mypack; package main; $var={}; $ref=\$var; dd bless $ref, "mypack"'
# $VAR1 = bless( do{\(my $o = {})}, 'mypack' )


# $ perl -Mdd -e 'package mypack; package main; $var={}; $ref=\$var; $obj=bless $ref, "mypack"; dd bless $obj, "mypack"'
# $VAR1 = bless( do{\(my $o = {})}, 'mypack' );

# $ perl -Mdd -e 'package mypack; package main; $var={}; $ref=\$var; $obj=bless $ref, "mypack"; dd bless \$obj, "mypack"'
# $VAR1 = bless( do{\(my $o = bless( do{\(my $o = {})}, 'mypack' ))}, 'mypack' );

# $ perl -Mdd -e 'package mypack; package main; $var={}; $ref=\$var; $obj=bless $ref, "mypack"; dd bless (bless( [], "mypack"), "mypack")'
# $VAR1 = bless( [], 'mypack' );









# $ perl -Mdd -e 'package mypack; package main; $ref={}; dd bless $ref, "mypack"'
# $VAR1 = bless( {}, 'mypack' );
# 
# $ perl -Mdd -e 'package mypack; package main; $ref=[]; dd bless $ref, "mypack"'
# $VAR1 = bless( [], 'mypack' );
# 
# $ perl -Mdd -e 'package mypack; package main; $ref=\(my $var=5); dd bless $ref, "mypack"'
# $VAR1 = bless( do{\(my $o = 5)}, 'mypack' );
# 
# 
# $ perl -Mdd -e 'package mypack; package main; $ref={}; $obj=bless $ref, "mypack"; dd bless $obj, "mypack"'
# $VAR1 = bless( {}, 'mypack' );
# 
# $ perl -Mdd -e 'package mypack; package main; $ref=[]; $obj=bless $ref, "mypack"; dd bless $obj, "mypack"'
# $VAR1 = bless( [], 'mypack' );
# 
# $ perl -Mdd -e 'package mypack; package main; $ref=\(my $var=5); $obj=bless $ref, "mypack"; dd bless $obj, "mypack"'
# $VAR1 = bless( do{\(my $o = 5)}, 'mypack' );





# BUG

# without substitutions

# london@archlinux:~/perl/scripts/json
# $ json_greppath avril.json rele
# ->{"description"}->"Avril Lavigne's unreleased track from 1st album Let Go.\r\nCheck this out."
# ->{"release_date"}->null
# ->{"release_year"}->null
# london@archlinux:~/perl/scripts/json
# 

# without substitutions

# london@archlinux:~/perl/scripts/json
# $ perl -Mdd -le 'use JSON; $file=<>;$text=decode_json($file); dd $text' avril.json | ./datadumper_greppath_dfa.pl
# ->{"creator"}->undef
# ->{"description"}->"Avril Lavigne\'s unreleased track from 1st album Let Go.
# Check this out."
# ->{"dislike_count"}->undef
# ->{"display_id"}->"A11_g4Pn920"

# with substitutions

# london@archlinux:~/perl/scripts/json
# $ perl -Mdd -le 'use JSON; $file=<>;$text=decode_json($file); dd $text' avril.json | ./datadumper_greppath_dfa.pl
# ->{"_filename"}->"Avril Lavigne - Let Go-A11_g4Pn920.mp4"
# ->{"abr"}->160
# ->{"acodec"}->"opus"
# ->{"age_limit"}->0
# ->{"album"}->undef
# ->{"alt_title"}->undef
# ->{"annotations"}->undef
# ->{"artist"}->undef
# ->{"automatic_captions"}->{}
# ->{"average_rating"}->"4.8965516"
# ->{"categories"}->[0]->"Music"
# ->{"channel_id"}->"UCq1uQaUciYH25EZ2rkW5xMQ"
# ->{"channel_url"}->"http://www.youtube.com/channel/UCq1uQaUciYH25EZ2rkW5xMQ"
# ->{"chapters"}->undef
# ->{"creator"}->undef
# ->{"description"}->"Avril Lavigne\'s unreleased track from 1st album Let Go.\r\nCheck this out."
# ->{"dislike_count"}->undef
# ->{"display_id"}->"A11_g4Pn920"
# ->{"duration"}->248

# BUG


# $VAR1 = bless( {
#                  'tree' => [
#                              'root',
#           ........
#                }, 'Mojo::DOM::HTML' );



# BUG


# 
# TOKEN string VALUE  html
# BEFORE array_comma
# STATE array_comma
# AFTER array_value
# 
# TOKEN array_comma VALUE ,
# BEFORE array_value
# STATE array_value
# AFTER array_comma
# 
# TOKEN reference VALUE $VAR1->{'tree'}
# BEFORE array_comma
# STATE array_comma
# AFTER undefined
# Use of uninitialized value $state in hash element at /home/london/perl/scripts/json/datadumper_greppath_dfa.pl line 482, <STDIN> chunk
# 1.
# Can't use an undefined value as a subroutine reference at /home/london/perl/scripts/json/datadumper_greppath_dfa.pl line 482, <STDIN> chunk 1.
# london@archlinux:/home/madrid/0Videos/TV Series/SKINS
# $


# BUG
# london@archlinux:/home/madrid/0Videos/TV Series/SKINS
# $ perl -MMojo::DOM::HTML -Mdd -le '$/=undef; $file=<>; $html = Mojo::DOM::HTML->new; dd $html->parse($file);' Cook\ sees\ Effy\ at\ Party\ -\ Skins\ Fire\ \&\ Rise\ -\ YouTube.html | vipe | datadumper_greppath
# Complex regular subexpression recursion limit (65534) exceeded at /home/london/perl/scripts/json/datadumper_greppath_dfa.pl line 143, <STDIN> chunk 1.


# london@archlinux:/home/madrid/0Videos/TV Series/SKINS
# $ perl -MMojo::DOM::HTML -Mdd -le '$/=undef; $file=<>; $html = Mojo::DOM::HTML->new; dd $html->parse($file);' Cook\ sees\ Effy\ at\ Party\ -\ Skins\ Fire\ \&\ Rise\ -\ YouTube.html | vipe | datadumper_greppath | head
# Complex regular subexpression recursion limit (65534) exceeded at /home/london/perl/scripts/json/datadumper_greppath_dfa.pl line 153, <STDIN> chunk 1.



# change order of cli arguments ?

# ./script.pl switches regexes FILE
# instead of
# ./script.pl FILE switches regexes

# add comments in regexes of tokeniner for string and number like
# escape, ...
#

# BUGS

# CLI OPTION PARSING PROBLEM
# jq '' ~/test3.json  | json_greppath			# works fine
# jq '' ~/test3.json  | json_greppath http		# no output
# json_greppath test3.json http					# works fine

# COLOR BUG
# ./json_greppath_dfa.pl avril.json yes
# SOLUTION  --> push pop color  NO save color into $current_color, then do RESET . $current_color

# ./json_greppath_dfa.pl avril.json yes   --> bold red on the middle of gree not enough contrast


# DFA REWORK

# cation/xml;q=0.9,*/*;q=0.8", "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3567.1 Safari/537.36"}, "acodec": "mp4a.40.2"}], "playlist_uploader_id": "labdbio", "channel_url": "http://www.youtube.com/channel/UCq1uQaUciYH25EZ2rkW5xMQ", "resolution": null, "vcodec": "avc1.4d401e", "n_entries": 14}  ( HERE --> )"text"
# 
# Expected any of :
#   curly_close    }													# WRONG
#   square_close   ]													# WRONG
#   comma          ,													# WRONG
#   end            EOF or start of an other JSON object / array			# RIGHT
# 
 
########################################################################################################3





