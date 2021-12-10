#!/usr/bin/perl

use strict;
use warnings;

#my @stack;
our @stack;
my @paths;
#my ($token, $value);
our ($token, $value);
my $container;
our $token_number = 1;


$,="\t";
# $\="\n";
$\="";

sub is_string_a_terminal_value {
	
	my $container = shift;

	if ($container eq "object") {
		if ($stack[$#stack]->{type} eq "colon") { # the string is the value of a key/value pair
			return 1;
		}
		elsif ($stack[$#stack]->{type} eq "comma"		# the string is the key of a key/value pair
			or $stack[$#stack]->{type} eq "curly_open")	# the string is the key of the first key/value pair of the object
		{
			return 0;
		}
		else {
			print "is_string_a_terminal_value() -> expected curly_open, colon or comma before a string in an object\n";
			exit;
		}
	}
	elsif ($container eq "array") {
		return 1;
	}
}

sub innermost_container {

	my $i = $#stack;
	my $in_object = undef;

	for ($i = $#stack; $i >= 0; $i--) {
		if ($stack[$i]->{type} eq "curly_open") {
		# the string is inside an object, it is either a key or a value
			return "object";
		}
		elsif ($stack[$i]->{type} eq "square_open") {
		# the string is a value of an array
			return "array";
		}
	}
	print "innermost_container() -> couldn't find innermost container\n";
	exit;
}

sub delete_value {
	my $value_type = shift;
	my $opening_token;
	my $container = innermost_container();

	if ($value_type eq "array") {
		$opening_token = "square_open";
#		print "SQUARE_OPEN";
	}
	elsif ($value_type eq "object") {
		$opening_token = "curly_open";
#		print "CURLY_OPEN";
	}
	elsif ($value_type eq "string") {
		if ($container eq "object") {
			if ($stack[$#stack]->{type} eq "colon") {
				pop @stack;									# delete colon
			}
			else {
				print "delete_value() 1 -> value doesn't have a colon before, in an object\n";
				exit;
			}
			if ($stack[$#stack]->{type} eq "string") {
				pop @stack;									# delete key
			}
			else {
				print "delete_value() 2 -> value doesn't have a key before, in an object\n";
				exit;
			}
		}
		elsif ($container eq "array") {
		}
		return;
	}

	while ($stack[$#stack]->{type} ne $opening_token) {
		pop @stack;
	}
	if ($stack[$#stack]->{type} eq $opening_token) {
		pop @stack;
	}
	else {
		print "delete_value() 3 -> could not found $opening_token\n";
		exit;
	}
	

	if ($container eq "array") {
	# if it is the value of an array, just delete this array
	# already done in the while loop above
		1;
	}
	elsif ($container eq "object") {
	# if it is the value of a key/value pair, just delete the key/value pair
		if ($stack[$#stack]->{type} eq "colon") {
			pop @stack;									# delete colon
		}
		else {
			print "delete_value() 4 -> value doesn't have a colon before, in an $value_type\n";
			exit;
		}
		if ($stack[$#stack]->{type} eq "string") {
			pop @stack;									# delete key
		}
		else {
			print "delete_value() 5 -> value doesn't have a colon before, in an $value_type\n";
			exit;
		}
		# PLUS delete following comma if any
	}
	# or this could be the root object
	# if root object -> end of processing
}

#sub record_path {
#	push @paths, [@stack];
#}


my @history;


while (<STDIN>) {
	print;
	($token, $value) = split /\s+/, $_;

	if    ($token eq "curly_open")   { push @stack, {type=>$token, value=>$value} }
	elsif ($token eq "square_open")  { push @stack, {type=>$token, value=>$value} }
	elsif ($token eq "colon")        { push @stack, {type=>$token, value=>$value} }
	elsif ($token eq "comma")        { push @stack, {type=>$token, value=>$value} #}
										unless $stack[$#stack]->{type} eq "comma"
										    or $stack[$#stack]->{type} eq "curly_open"
										    or $stack[$#stack]->{type} eq "square_open" }
	# UNLESS --> for when the (key/) value just before has been deleted

	elsif ($token eq "whitespace")   { 1; }

	elsif ($token eq "curly_close")  { delete_value("object") }
	elsif ($token eq "square_close") { delete_value("array")  }

	elsif ($token eq "true")         { push @paths, [@stack] }
	elsif ($token eq "false")        { push @paths, [@stack] }
	elsif ($token eq "null")         { push @paths, [@stack] }
	elsif ($token eq "number")       { push @paths, [@stack] }
	elsif ($token eq "string") {
		$container = innermost_container();
		if (is_string_a_terminal_value($container) ) {
#			print "TERMINAL";
			push @paths, [@stack];
			delete_value("string");
		}
		else { # then it is the key of a key/value pair
#			print "KEY";
			push @stack, {type=>$token, value=>$value};
		}
	}
	
	$token_number++;
}
#print scalar @paths;

# print in a well prsented way @every_root_to_leaf

# transform @every_root_to_leaf in an array of strings

# make a way to print grep into this array of strings


# make an other script that contains this one plus json_tokenizer and rename it grepjson ?


#print @history;




#ReadMode 0;

__END__

terminal values -> string number true false null

object -> key / value pairs
array  -> values

a string can be either a key (of an object) or a value

if in an object
	if colon just before (string|number|true|false|null),
		then it is a terminal VALUE
	elsif comma or curly_open just before
		then it is a KEY (comma)
if in an array
	then it is a value


$ /home/london/perl/scripts/json_tokenizer.pl raoult.json | awk '{print $1}' | sort | uniq -c
   6359 colon
   3390 comma
   3190 curly_close
   3190 curly_open
     51 false
    330 number
    522 square_close
    522 square_open
   9130 string
    238 true
      1 whitespace
