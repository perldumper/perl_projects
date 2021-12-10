#!/usr/bin/perl

use strict;
use warnings;
#use Term::ReadKey;

#ReadMode 1; # allow Ctrl-C, crash with Ctrl-D, space have to be followed by enter
#ReadMode 2; # allow Ctrl-C, crash with Ctrl-D, space have to be followed by enter
#ReadMode 3; # allow Ctrl-C but not Ctrl-D,     allow alone space
#ReadMode 4; # doesn't allow Ctrl-C nor Ctrl-D, allow alone space

#perl/scripts/json_tokenizer.pl raoult.json | perl/scripts/json_root_to_leaves.pl
#cat raoult.json | sed 's/{/\n{/g' | vim -
#perl/scripts/json_tokenizer.pl raoult.json | head -30 | nl


# CALL STACK




#my @stack;
our @stack;
my @paths;
#my ($token, $value);
our ($token, $value);
my $container;
our $token_number = 1;


sub step {
#		local $\="\n";
#		return;
#		my ($reg_pos, $reg_len, $str_pos, $text) = @_;
#		my ($wchar,$hchar)=GetTerminalSize();
#		system("clear");

	my $history = "";
	$,="\n";
	$\="\n";
#	system("clear");
#	print "\n" x 90;
#	foreach (reverse @stack) {
	foreach (@stack) {
		$history .= sprintf "%-20s %s\n", $_->{type}, $_->{value};
	}
#	my $key = ReadKey();
#	while(ReadKey() ne "\n"){1;}
#	while(ReadKey() eq "\n"){1;}
#	sleep 1;
	return $history;
}



$,="\t";
$\="\n";

sub is_string_a_terminal_value {
	
	my $container = shift;

	if ($container eq "object") {
		if ($stack[$#stack]->{type} eq "colon") {
		# key/value pairs are separated by a colon
			return 1;
		}
		elsif ($stack[$#stack]->{type} eq "comma"
			or $stack[$#stack]->{type} eq "curly_open")
		{ # the string is a key
			return 0;
		}
		else {
#			print $token_number, $token, $value;
#			print "is_string_a_terminal_value -> expected curly_open, colon or comma before a string in an object\n";
			print $_->{type}, $_->{value} foreach @stack;
#			print "STACK SIZE", scalar @stack;
#			exit;
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
#	print $token_number, $token, $value;
#	print "innermost_container -> couldn't find innermost container\n";
#	print $_->{type}, $_->{value} foreach @stack;
#	print "STACK SIZE", scalar @stack;
#	exit;
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
#				print $token_number, $token, $value;
#				print "delete_value 1 -> value doesn't have a colon before, in an object\n";
#				print $_->{type}, $_->{value} foreach @stack;
#				print "STACK SIZE", scalar @stack;
#				exit;
			}
			if ($stack[$#stack]->{type} eq "string") {
				pop @stack;									# delete key
			}
			else {
#				print $token_number, $token, $value;
#				print "delete_value 2 -> value doesn't have a key before, in an object\n";
#				print $_->{type}, $_->{value} foreach @stack;
#				print "STACK SIZE", scalar @stack;
#				exit;
			}
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
#		print $token_number, $token, $value;
#		print "delete_value 3 -> could not found $opening_token\n";
#		print $_->{type}, $_->{value} foreach @stack;
#		print "STACK SIZE", scalar @stack;
#		exit;
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
#			print $token_number, $token, $value;
#			print "delete_value 4 -> value doesn't have a colon before, in an $value_type\n";
#			print $_->{type}, $_->{value} foreach @stack;
#			print "STACK SIZE", scalar @stack;
			exit;
		}
		if ($stack[$#stack]->{type} eq "string") {
			pop @stack;									# delete key
		}
		else {
#			print $token_number, $token, $value;
#			print "delete_value 5 -> value doesn't have a colon before, in an $value_type\n";
#			print $_->{type}, $_->{value} foreach @stack;
#			print "STACK SIZE", scalar @stack;
#			exit;
		}
		# PLUS delete following comma if any
	}
	# or this could be the root object
	# if root object -> end of processing
}

#sub record_path {
#	push @paths, [@stack];
#}

my $key;
#my @STDIN = <STDIN>;
#while(ReadKey() ne "\n" ){
#print @stack;

my @history;

open my $FH, "./json_tokenizer.pl raoult.json |";


#while (<STDIN>) {
#foreach (@STDIN) {
while (<$FH>) {
	($token, $value) = split /\s+/, $_;

#	print ($token, $value);
#	push @history, step();

	print step();

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
#	step();
	
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
