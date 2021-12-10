#!/usr/bin/perl

# https://www.json.org/json-en.html

use strict;
use warnings;	# sub print_grep_color() -> Use of uninitialized value in print at ./json_greppath.pl line 451, <> chunk 1
use utf8;		# required ?

# same output color as grep (1)
use constant   RESET => "\e[0m";
use constant    BOLD => "\e[1m";
use constant     RED => "\e[31m";

my $json;
my $jq_output = 0;
$/=undef;

if (@ARGV) {
	if (-e $ARGV[0]) { local @ARGV = shift; $json = <ARGV>   }
	else             { $json = shift }
}
elsif (not -t STDIN) { $json = <STDIN>  }
else {
print STDERR <<"USAGE";
  usage :        json_greppath FILE [jq] [-i] [not] [and|or] [--] [PATTERNS]
      cat FILE | json_greppath      [jq] [-i] [not] [and|or] [--] [PATTERNS]
USAGE
exit;
}

if (@ARGV) {
	if ($ARGV[0] =~ /^-{0,2}jq$/ ) { $jq_output = 1; shift }
}


# tokenizer
my $end = 0;
my @tokens;
# stack-based tree walking
my @stack;
my @paths;
my @indexes;
my ($token,$value);
my $container;

while(not $end){

	if    ($json =~ m/\G  \{    /gcx)  { push @tokens,  {type=> "curly_open",     value=> "{"     } }
	elsif ($json =~ m/\G  \}    /gcx)  { push @tokens,  {type=> "curly_close",    value=> "}"     } }
	elsif ($json =~ m/\G  \[    /gcx)  { push @tokens,  {type=> "square_open",    value=> "["     } }
	elsif ($json =~ m/\G  \]    /gcx)  { push @tokens,  {type=> "square_close",   value=> "]"     } }
	elsif ($json =~ m/\G   ,    /gcx)  { push @tokens,  {type=> "comma",          value=> ","     } }
	elsif ($json =~ m/\G   :    /gcx)  { push @tokens,  {type=> "colon",          value=> ":"     } }
	elsif ($json =~ m/\G  true  /gcx)  { push @tokens,  {type=> "true",           value=> "true"  } }
	elsif ($json =~ m/\G  false /gcx)  { push @tokens,  {type=> "false",          value=> "false" } }
	elsif ($json =~ m/\G  null  /gcx)  { push @tokens,  {type=> "null",           value=> "null"  } }

	elsif ($json =~ m/\G([ \n\r\t]+)/gc) { 1; }	# more laxed version of whitespace than specification
					# allows the tokenizing of multiple JSON in a single file and separated by newlines

	#-----------------------------------------------------------------------------
	#	any unicode codepoint except " or \ or control characters
	#	[^"\\]  ???

	elsif ($json =~ m@\G	\"	(
				(?:			
					   [^"\\]
				|   (?: \\["\\/bfnrt] | \\u[0-9a-fA-F]{4} )

				)*
						)	\"
					@gcx) { push @tokens,  {type=>"string", value=>$1} }

	#-----------------------------------------------------------------------------
	elsif ($json =~ m/\G(  [-]?	(?: 0 | [1-9] [0-9]* ) 
								(?: \. [0-9]+  )?			(?# fraction)
								(?: [eE] [-+]? [0-9]+ )?	(?# exponent)

					)/gcx) { push @tokens, {type=>"number", value=>$1} }
	#-----------------------------------------------------------------------------

	else { $end = 1 }
}

sub is_string_a_terminal_value {
	
	my $container = shift;

	if ($container eq "object") {
		if ($stack[-1]->{type} eq "colon") { # the string is the value of a key/value pair
			return 1;
		}
		elsif ($stack[-1]->{type} eq "comma"		# the string is the key of a key/value pair
			or $stack[-1]->{type} eq "curly_open")	# the string is the key of the first key/value pair of the object
		{
			return 0;
		}
		else { die "is_string_a_terminal_value() -> expected curly_open, colon or comma before a string in an object\n" }
	}
	elsif ($container eq "array") {
		return 1;
	}
}

sub innermost_container {

	my $value = shift;
	my $opening_token;
	my $i = $#stack;

	# get past the opening curly brace or opening square brace if the value we are searching for the innermost container
	# is an object or an array
	if (defined $value) {
		if ($value eq "object")   { $opening_token = "curly_open"  }
		elsif ($value eq "array") { $opening_token = "square_open" }

		while ($stack[$i]->{type} ne $opening_token and $i > 0 ) { $i-- }

		if ($stack[$i]->{type} eq $opening_token)   { $i-- }
		elsif ($stack[0]->{type} eq $opening_token) { $i-- }
		else { die "innermost_container() 1 -> opening token of $value value not found\n" }
	}

	for (; $i >= 0; $i--) {
		if ($stack[$i]->{type} eq "curly_open") { return "object" }
		# the string is inside an object, it is either a key or a value

		elsif ($stack[$i]->{type} eq "square_open") { return "array" }
		# the string is a value of an array
	}
	return "" if @stack == 1;
	die "innermost_container() 2 -> couldn't find innermost container\n";
}

sub delete_value {
	my $value_type = shift;
	my $container = shift;
	my $opening_token;

	if ($value_type eq "array")     { $opening_token = "square_open" }
	elsif ($value_type eq "object") { $opening_token = "curly_open" }

	elsif ($value_type eq "string") {
		if ($stack[-1]->{type} eq "string") { pop @stack; } # delete key
		else { die "delete_value() 1 -> string value not found\n" }

		if ($container eq "object") {
			if ($stack[-1]->{type} eq "colon") {
				pop @stack;									# delete colon
			}
			else { die "delete_value() 2 -> value doesn't have a colon before, in an object\n" }

			if ($stack[-1]->{type} eq "string") {
				pop @stack;									# delete key
			}
			else { die "delete_value() 3 -> value doesn't have a key before, in an object\n" }
		}
		elsif ($container eq "array") {
			if ($stack[-1]->{type} eq "index") {
				pop @stack;
			}
			else { die "delete_value() 4 -> index not found\n" }
		}


		return;
	}
	elsif ($value_type eq "true" || $value_type eq "false" || $value_type eq "null" || $value_type eq "number") {
		if ($stack[-1]->{type} eq $value_type) {
			pop @stack;
		}
		else { die "delete_value() 5 -> $value_type not found\n" }

		if ($container eq "object") {
			if ($stack[-1]->{type} eq "colon") {
				pop @stack;									# delete colon
			}
			else { die "delete_value() 6 -> value doesn't have a colon before, in an object\n" }

			if ($stack[-1]->{type} eq "string") {
				pop @stack;									# delete key
			}
			else { die "delete_value() 7 -> value doesn't have a key before, in an object\n" }
		}
		elsif ($container eq "array") {
			if ($stack[-1]->{type} eq "index") {			# delete index
				pop @stack;
			}
			else { die "delete_value() 8 -> index not found\n" }
		}

		return;
	}

	while ($stack[-1]->{type} ne $opening_token) {
		pop @stack;
	}
	if ($stack[-1]->{type} eq $opening_token) {
		pop @stack;
	}
	else { die "delete_value() 9 -> could not found $opening_token\n" }
	

	if ($container eq "array") {	# ["value",{"key":"value"}]
	# if it is the value of an array, just delete this array
	# already done in the while loop above
		if ($stack[-1]->{type} eq "index") {			# delete index
			pop @stack;
		}
		else { die "delete_value() 10 -> index not found\n" }
	}
	elsif ($container eq "object") {
	# if it is the value of a key/value pair, just delete the key/value pair
		if ($stack[-1]->{type} eq "colon") {
			pop @stack;									# delete colon
		}
		else { die "delete_value() 11 -> value doesn't have a colon before\n" }

		if ($stack[-1]->{type} eq "string") {
			pop @stack;									# delete key
		}
		else { die "delete_value() 12 -> colon value doesn't have a string before\n" }

		# PLUS delete following comma if any
	}
	# or this could be the root object
	# if root object -> end of processing
}

while ($_ = shift @tokens) {

	($token, $value) = ( $_->{type}, $_->{value} );

	if ($token eq "curly_open") {
		if (@stack) {
			push @stack, {type => "index", value => $indexes[-1]} if innermost_container() eq "array";
		}
		push @stack, {type => "curly_open",  value => "{" };
	}

	elsif ($token eq "square_open") {
		if (@stack) {
			push @stack, {type => "index", value => $indexes[-1]} if innermost_container() eq "array";
		}
		if (@indexes) { push @indexes, 0 }
		else          { $indexes[0]  = 0 }
		push @stack, {type => "square_open", value => "[" };
	}

	elsif ($token eq "colon") { push @stack, {type => "colon", value => ":" } }

	elsif ($token eq "comma") { push @stack, {type => "comma", value => "," }
									unless $stack[-1]->{type} eq "comma"			# unless preceding values have been deleted
									    or $stack[-1]->{type} eq "curly_open"
									    or $stack[-1]->{type} eq "square_open" }

	elsif ($token eq "curly_close")  {
		if (innermost_container("object") eq "array" ) {
			$indexes[-1]++;
		}
		delete_value("object", innermost_container("object") );
		# delete everything until, and including, the matching "{"
		# plus string and colon directly before if in an object
	}

	elsif ($token eq "square_close") {
		pop @indexes;
		if (innermost_container("array") eq "array" ) {
			$indexes[-1]++;
		}
		delete_value("array", innermost_container("array") );
		# delete everything until, and including, the matching "["
		# plus string and colon directly before if in an object
	}

	# TERMINAL VALUES

	elsif ($token eq "true") {
		if (innermost_container() eq "array" ) {
			push @stack, {type => "index", value => $indexes[-1]} if innermost_container() eq "array";
			$indexes[-1]++;
		}
		push @stack, {type => "true", value => "true"};
		push @paths, [@stack];
		delete_value("true", innermost_container() );
	}

	elsif ($token eq "false") {
		if (innermost_container() eq "array" ) {
			push @stack, {type => "index", value => $indexes[-1]} if innermost_container() eq "array";
			$indexes[-1]++;
		}
		push @stack, {type => "false", value => "false"};
		push @paths, [@stack];
		delete_value("false", innermost_container() );
	}

	elsif ($token eq "null") {
		if (innermost_container() eq "array" ) {
			push @stack, {type => "index", value => $indexes[-1]} if innermost_container() eq "array";
			$indexes[-1]++;
		}
		push @stack, {type => "null", value => "null"};
		push @paths, [@stack];
		delete_value("null", innermost_container() );
	}

	elsif ($token eq "number") {
		if (innermost_container() eq "array" ) {
			push @stack, {type => "index", value => $indexes[-1]} if innermost_container() eq "array";
			$indexes[-1]++;
		}
		push @stack, {type => "number", value => $value};
		push @paths, [@stack];
		delete_value("number", innermost_container() );
	}

	elsif ($token eq "string") {
		$container = innermost_container();
		
		if (is_string_a_terminal_value($container) ) {	# if not, then it is the key of a k/v pair
			if (innermost_container() eq "array" ) {
				push @stack, {type => "index", value => $indexes[-1]} if innermost_container() eq "array";
				$indexes[-1]++;
			}
			push @stack, {type => "string", value => $value};
			push @paths, [@stack];
			delete_value("string", $container );	
		}
		else {
			push @stack, {type => "string", value => $value};
		}
	}

}


my @path;
my @keys_and_values;	# allows regex_patterns to match individual keys/index/terminal values
						# and not in the entire string of one path.       example:  ^format$

# PREPARE THE PATH INFORMATION SO THAT IT IS SUITABLE BOTH FOR SEARCHING AND FOR PRETTY PRINTED OUTPUT

foreach my $branch (@paths) {
	@path = ();
	push @keys_and_values, [];

	for(my $i=0; $i < $branch->$#*; $i++) {		# processing terminal vaulue below
		$_ = $branch->[$i];

		next if $_->{type} eq "colon"
		 	or	$_->{type} eq "comma"			# comma case needed ?
		 	or	$_->{type} eq "curly_open"
			or	$_->{type} eq "square_open";

		if ( $_->{type} eq "string") {				# STRING OF A KEY
			push $keys_and_values[-1]->@*,  $_;
		}
		elsif ( $_->{type} eq "index") {			# INDEX
			push $keys_and_values[-1]->@*,  $_;
		}
	}

	if ($branch->[-1]->{type} eq "string") {	# STRING TERMINAL VALUE
		push $keys_and_values[-1]->@*,  $branch->[-1];
	}
	else {										# OTHER TERMINAL VALUE
		push $keys_and_values[-1]->@*, $branch->[-1];
	}

}


sub print_grep_color {
	my $json_paths_to_grep = shift;
	my $patterns = shift;
	my $logic = shift;				# and / or
	my $not = shift;				# negative
	my $case_insensitive = shift;	# case insensitive or not
	my $color = shift;

	my $flip_flop;
	my $flip_flop_pat;
	my @pos_pat;
	my @pos;
	my %have_pattern_matched;

	my $path;
	my $pat;
	my $key;
	my $line;
	my $i;
	my $j;
	local $\="";
	local $,="";	

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

	# FOR EACH PATH
	while ($path = shift $json_paths_to_grep->@*) {
		%have_pattern_matched = map { $_ => 0 } $patterns->@*;

		if ($jq_output) { $line = "" } else { $line = "->" }

		# FOR EACH KEY or INDEX, plus the TERMINAL VALUE
		for ( $j=0; $j < $path->@*; $j++) {
			$key = $path->[$j]->{value};	# key / index / terminal value of the path
			@pos = ();
			$flip_flop = "0" x length $key;

			# FROM THE ARRAY OF POSITIONS OF MATCHES OF EACH PATTERN
			# OBTAIN THE OVERLAPPING ARRAY OF POSITIONS,
			# SO THE MATCHES CAN BE COLORED IN RED

			foreach $pat ($patterns->@*) {
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
					$have_pattern_matched{$pat} = $have_pattern_matched{$pat} | 1;	# bitwise-OR, logical-OR doesn't work for this
				}
				else {
					$have_pattern_matched{$pat} = $have_pattern_matched{$pat} | 0;
				}
			}

			# get the overlapping start and end positions of substrings that match for all the regex patterns
			# to obtain one flip-flop seqence of match / outside match alternation
			while ($flip_flop =~ /(1+)/g) {
				push @pos, [$-[0], $+[0]];
			}

			# PRETTY OUTPUT
			# put double-quotes around strings, { } around object keys and [ ] around array indexes
			if ($path->[$j]->{type} eq "string" and $j < $path->$#* ) {		# key
				if ($jq_output) {
					if ($path->[$j]->{value} =~ / / ) {
						$line .= ".\""
					}
					else { $line .= "." }
				}
				else { $line .= "{\"" }
			}
			elsif ($path->[$j]->{type} eq "string" and $j == $path->$#* ) {	# string terminal value
				if ($jq_output) {
					$line .= " --> \"";
				}
				else { $line .= "\"" }
			}
			elsif ($path->[$j]->{type} eq "index") {						# array index
				$line .= "["
			}
			elsif ($jq_output) { $line .= " --> " }							# terminal value that is not a string

			# COMPOSE THE LINE. ALTERNANCE OF COLORLESS AND COLORED (segments that match) SUBSTRINGS
			if (@pos and $color) {						# if at least one match in the current line
				$line .= substr $key, 0, $pos[0]->[0];									# before first match COLORLESS

				for($i=0; $i < @pos; $i++) {
					$line .=  BOLD . RED . substr($key, $pos[$i]->[0], $pos[$i]->[1] - $pos[$i]->[0]) . RESET;	# match COLORED
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
			if ($path->[$j]->{type} eq "string" and $j < $path->$#* ) {		# key
				if ($jq_output) {
					if ($path->[$j]->{value} =~ / / ) {
						$line .= ".\""
					}
				}
				else { $line .= "\"}->" }
			}
			elsif ($path->[$j]->{type} eq "string" and $j == $path->$#* ) {	# string terminal value
				$line .= "\""
			}
			elsif ($path->[$j]->{type} eq "index") {						# array index
				if ($jq_output) {
					$line .= "]"
				}
				else { $line .= "]->" }
			}

		}

		if ($logic eq "or") {
			if ($not) {
				print $line . "\n" unless reduce_or(values %have_pattern_matched);
			}
			else {
				print $line . "\n" if reduce_or(values %have_pattern_matched);
			}
		}
		elsif ($logic eq "and") {
			if ($not) {
				print $line . "\n" unless reduce_and(values %have_pattern_matched);
			}
			else {
				print $line . "\n" if reduce_and(values %have_pattern_matched);
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
	print_grep_color(\@keys_and_values, [], "print all");
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
	elsif ($ARGV[0] eq "--") {						# END OF OPTIONS, START OR REGEXES
		shift;
		last;
	}
}

print_grep_color(\@keys_and_values, \@ARGV, $logic, $not, $case_insensitive, $color);


