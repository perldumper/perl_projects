#!/usr/bin/perl

# https://www.json.org/json-en.html

use strict;
use warnings;
use utf8;  # required ?

use constant   RESET => "\e[0m";
use constant    BOLD => "\e[1m";
use constant     RED => "\e[31m";

my $json;
$/=undef;

if (@ARGV) {
	if (-e $ARGV[0]) { local @ARGV = shift; $json = <ARGV>   }
	else             { $json = shift }
}
elsif (not -t STDIN) { $json = <STDIN>  }
else                 { exit }

my $end = 0;
my @tokens;
my @stack;
my @paths;
my @indexes;
my ($token,$value);
my $container;

while(not $end){

	if   ($json =~ m/\G  \{    /gcx)  { push @tokens,  {type=> "curly_open",     value=> "{"     } }
	elsif($json =~ m/\G  \}    /gcx)  { push @tokens,  {type=> "curly_close",    value=> "}"     } }
	elsif($json =~ m/\G  \[    /gcx)  { push @tokens,  {type=> "square_open",    value=> "["     } }
	elsif($json =~ m/\G  \]    /gcx)  { push @tokens,  {type=> "square_close",   value=> "]"     } }
	elsif($json =~ m/\G   ,    /gcx)  { push @tokens,  {type=> "comma",          value=> ","     } }
	elsif($json =~ m/\G   :    /gcx)  { push @tokens,  {type=> "colon",          value=> ":"     } }
	elsif($json =~ m/\G  true  /gcx)  { push @tokens,  {type=> "true",           value=> "true"  } }
	elsif($json =~ m/\G  false /gcx)  { push @tokens,  {type=> "false",          value=> "false" } }
	elsif($json =~ m/\G  null  /gcx)  { push @tokens,  {type=> "null",           value=> "null"  } }

	elsif($json =~ m/\G([ \n\r\t]+)/gc) { 1; }

	#-----------------------------------------------------------------------------
	#	(?: any unicode codepoint except " or \ or control characters )
	#	[^"\\]  ???

	elsif($json =~ m@\G	\"	(
				(?:			
					   [^"\\]
				|   (?: \\["\\/bfnrt] | \\u[0-9a-fA-F]{4} )

				)*
						)	\"
					@gcx) { push @tokens,  {type=>"string", value=>$1} }

	#-----------------------------------------------------------------------------
	elsif($json =~ m/\G(  [-]?	(?: 0 | [1-9] [0-9]* ) 
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

	# get past the curly brace or square brace if the value we are finding the innermost container
	# is an object or an array
	if (defined $value) {
		if ($value eq "object")   { $opening_token = "curly_open"  }
		elsif ($value eq "array") { $opening_token = "square_open" }

		while ($stack[$i]->{type} ne $opening_token and $i > 0 ) { $i-- }

		if ($stack[$i]->{type} eq $opening_token)   { $i-- }
		elsif ($stack[0]->{type} eq $opening_token) { $i-- }
		else { die "innermost_container() -> opening token of $value value not found\n" }
	}

	for (; $i >= 0; $i--) {
		if ($stack[$i]->{type} eq "curly_open") { return "object" }
		# the string is inside an object, it is either a key or a value

		elsif ($stack[$i]->{type} eq "square_open") { return "array" }
		# the string is a value of an array
	}
	return "" if @stack == 1;
	die "innermost_container() -> couldn't find innermost container\n";
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
			else { die "delete_value() -> index not found\n" }
		}


		return;
	}
	elsif ($value_type eq "true" || $value_type eq "false" || $value_type eq "null" || $value_type eq "number") {
		if ($stack[-1]->{type} eq $value_type) {
			pop @stack;
		}
		else { die "delete_value() 4 -> $value_type not found\n" }

		if ($container eq "object") {
			if ($stack[-1]->{type} eq "colon") {
				pop @stack;									# delete colon
			}
			else { die "delete_value() 5 -> value doesn't have a colon before, in an object\n" }

			if ($stack[-1]->{type} eq "string") {
				pop @stack;									# delete key
			}
			else { die "delete_value() 6 -> value doesn't have a key before, in an object\n" }
		}
		elsif ($container eq "array") {
			if ($stack[-1]->{type} eq "index") {
				pop @stack;
			}
			else { die "delete_value() -> index not found\n" }
		}

		return;
	}

	while ($stack[-1]->{type} ne $opening_token) {
		pop @stack;
	}
	if ($stack[-1]->{type} eq $opening_token) {
		pop @stack;
	}
	else { die "delete_value() 7 -> could not found $opening_token\n" }
	

	if ($container eq "array") {	# ["value",{"key":"value"}]
	# if it is the value of an array, just delete this array
	# already done in the while loop above
		if ($stack[-1]->{type} eq "index") {
			pop @stack;
		}
		else { die "delete_value() -> index not found\n" }
	}
	elsif ($container eq "object") {
	# if it is the value of a key/value pair, just delete the key/value pair
		if ($stack[-1]->{type} eq "colon") {
			pop @stack;									# delete colon
		}
		else { die "delete_value() 8 -> value doesn't have a colon before\n" }

		if ($stack[-1]->{type} eq "string") {
			pop @stack;									# delete key
		}
		else { die "delete_value() 9 -> colon value doesn't have a string before\n" }

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

	elsif ($token eq "colon")        { push @stack, {type => "colon",       value => ":" } }

	elsif ($token eq "comma")        { push @stack, {type => "comma",       value => "," }
										unless $stack[-1]->{type} eq "comma"			# unless values have been deleted
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
			# leave the comma before the value that is deleted if not first k/v in object or not first str in array
			delete_value("string", $container );	
		}
		else {
			push @stack, {type => "string", value => $value};
		}
	}


}


my @path;
my @keys_and_values;
my @output;

foreach my $branch (@paths) {
	@path = ();
	push @keys_and_values, [];

	for(my $i=0; $i < $branch->$#*; $i++) {
		$_ = $branch->[$i];

		next if $_->{type} eq "colon"
		 	or	$_->{type} eq "comma"			# next if comma needed ?
		 	or	$_->{type} eq "curly_open"
			or	$_->{type} eq "square_open";

		if ( $_->{type} eq "string") {
			push @path, "{\"$_->{value}\"}";
			push $keys_and_values[-1]->@*,  $_->{value};
		}
		elsif ( $_->{type} eq "index") {
			push @path, "[" . $_->{value} . "]";
			push $keys_and_values[-1]->@*,  $_->{value};
		}
		else {
			push @path, $_->{value};
			push $keys_and_values[-1]->@*,  $_->{value};
		}
	}

	if ($branch->[-1]->{type} eq "string") {
		push @output, "->" . join("->", @path, "\"$branch->[-1]->{value}\"" ) . "\n";
		push $keys_and_values[-1]->@*,  $branch->[-1]->{value};
	}
	else {
		push @output, "->" . join("->", @path, $branch->[-1]->{value}) . "\n";
		push $keys_and_values[-1]->@*,  $branch->[-1]->{value};
	}

}

sub _grep {
	my $pattern = shift;
	my $case_insensitive = shift;
	my $line;
	my @pos;
	my $i;
	local $\="";
	local $,="";	

	while ($line = shift @_) {
		chomp $line;
		@pos = ();
		if (not $case_insensitive) {
			while ($line =~ /($pattern)/g) {	# find positions of all matches in a line
				push @pos, [$-[0], $+[0]];		# and foreach, push start and end positions in the line
			}
		}
		else {
			while ($line =~ /($pattern)/ig) {	# find positions of all matches in a line
				push @pos, [$-[0], $+[0]];		# and foreach, push start and end positions in the line
			}
		}
		if (@pos) {							# if at least one match in the current line
			print substr $line, 0, $pos[0]->[0];														# before first match

			for($i=0; $i < @pos; $i++) {
				print BOLD, RED, substr($line, $pos[$i]->[0], $pos[$i]->[1] - $pos[$i]->[0]), RESET;	# match
				if (defined $pos[$i+1]) {
					print      substr $line, $pos[$i]->[1], $pos[$i+1]->[0] - $pos[$i]->[1];			# in-between matches
				}
			}
# 			print substr $line, $pos[-1]->[1], length $line;											# after last match
# 			print  $line;											# after last match
# 			print substr($line, $pos[-1]->[1], length $line) if defined $pos[-1]->[1];					# after last match
			print substr($line, $pos[-1]->[1], length $line) if defined $pos[-1];					# after last match
		}

	}
}

if (@output != @keys_and_values) {
	die "\@output and \@keys_and_values don't have the same number of elements\n";
}

my $color;
if (-t STDOUT) { $color = 1 }
else           { $color = 0 }

if (@ARGV) {
	if ($ARGV[0] eq "-i") {
		if ($color) {
			print _grep $ARGV[1], 1, @output;
# 			for (my $i=0; $i < @output; $i++) {
# 				foreach ($keys_and_values[$i]->@*) {
# 					if ( m/$ARGV[1]/i ) {
# 						print _grep $ARGV[1], 1, $output[$i];
# 						next;
# 					}
# 				}
# 			}
		}
		else {
			print grep { /$ARGV[1]/i } @output;
# 			for (my $i=0; $i < @output; $i++) {
# 				foreach ($keys_and_values[$i]->@*) {
# 					if ( m/$ARGV[1]/i ) {
# 						print $output[$i];
# 						next;
# 					}
# 				}
# 			}
		}
	}
	else {
		if ($color) {
			print _grep $ARGV[0], 0, @output;
# 			for (my $i=0; $i < @output; $i++) {
# 				foreach ($keys_and_values[$i]->@*) {
# 					if ( m/$ARGV[0]/ ) {
# 						print _grep $ARGV[0], 0, $output[$i];
# 						next;
# 					}
# 				}
# 			}
		}
		else {
			print grep { /$ARGV[0]/ } @output;
# 			for (my $i=0; $i < @output; $i++) {
# 				foreach ($keys_and_values[$i]->@*) {
# 					if ( m/$ARGV[0]/ ) {
# 						print $output[$i];
# 						next;
# 					}
# 				}
# 			}
		}
	}
}
else {
	print @output
}








