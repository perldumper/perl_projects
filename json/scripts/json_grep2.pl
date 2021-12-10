#!/usr/bin/perl

use strict;
use warnings;
# use autodie;

# $,="";
# $,="\n";
# $\="";
# $\="\n";

my @stack;
my @paths;
my ($token,$value);
my $container;

sub is_string_a_terminal_value {
	
	my $container = shift;

	if ($container eq "object") {
		if ($stack[-2]->{type} eq "colon") { # the string is the value of a key/value pair
			return 1;
		}
		elsif ($stack[-2]->{type} eq "comma"		# the string is the key of a key/value pair
			or $stack[-2]->{type} eq "curly_open")	# the string is the key of the first key/value pair of the object
		{
			return 0;
		}
		else {
			print "is_string_a_terminal_value() -> expected curly_open, colon or comma before a string in an object\n";
			local $\="\n";
			print scalar @stack;
			for (my $i=0; $i<=$#stack; $i++) {
				print " $i $stack[$i]->{type}\t$stack[$i]->{value}";
			}
			exit;
		}
	}
	elsif ($container eq "array") {
		return 1;
	}
}

sub innermost_container {

	my $value = shift;
	my $opening_token;
	my $i = $#stack;

	if (defined $value) {
		if ($value eq "object") {
			$opening_token = "curly_open";
		}
		elsif ($value eq "array") {
			$opening_token = "square_open";
		}

# 		print uc "innermost defined value $value\n";
# 		print scalar @stack , "\n";

		while ($stack[$i]->{type} ne $opening_token and $i > 0 ) {
			print "$i $stack[$i]->{type}\t$stack[$i]->{value}\n";
			$i--;
		}

# 		print "$i $stack[$i]->{type}\t$stack[$i]->{value}\n";

		if ($stack[-1]->{type} eq $opening_token) {
			$i--;
		}
		elsif ($stack[0]->{type} eq $opening_token) {
			$i--;
		}
# 		elsif ( @stack > 2 ) {
# 		elsif ( @stack > 1 ) {
# 		elsif ( @stack > 0 ) {
# 		elsif ( @stack >= 0 ) {
		else {
			print "innermost_container() -> opening token of $value value not found\n";
			print "$i $stack[$i]->{type}\t$stack[$i]->{value}\n";
			exit;
		}
	}

	for (; $i >= 0; $i--) {
		if ($stack[$i]->{type} eq "curly_open") {
		# the string is inside an object, it is either a key or a value
			return "object";
		}
		elsif ($stack[$i]->{type} eq "square_open") {
		# the string is a value of an array
			return "array";
		}
	}
	return "root" if @stack == 1;
	print "innermost_container() -> couldn't find innermost container\n";
	exit;
}

sub delete_value {
	my $value_type = shift;
	my $container = shift;
	my $opening_token;

	if ($value_type eq "array") {
		$opening_token = "square_open";
	}
	elsif ($value_type eq "object") {
		$opening_token = "curly_open";
	}
	elsif ($value_type eq "string") {
		if ($stack[-1]->{type} eq "string") {
# 			print "\@poped 1 $stack[-1]->{type}\t$stack[-1]->{value}\n";
			pop @stack;									# delete key
		}
		else {
			print "delete_value() 0 -> string value not found\n";
			exit;
		}
		if ($container eq "object") {
			if ($stack[-1]->{type} eq "colon") {
# 				print "\@poped 2 $stack[-1]->{type}\t$stack[-1]->{value}\n";
				pop @stack;									# delete colon
			}
			else {
				print "delete_value() 1 -> value doesn't have a colon before, in an object\n";
				print "-1 $stack[-1]->{type}\t$stack[-1]->{value}";
				exit;
			}
			if ($stack[-1]->{type} eq "string") {
# 				print "\@poped 3 $stack[-1]->{type}\t$stack[-1]->{value}\n";
				pop @stack;									# delete key
			}
			else {
				print "delete_value() 2 -> value doesn't have a key before, in an object\n";
				exit;
			}
		}
		elsif ($container eq "array") {
# 			if ($stack[-1]->{type} eq "string") {
# 				print "\@poped 4 $stack[-1]->{type}\t$stack[-1]->{value}\n";
# 				pop @stack;									# delete value
# 			}
# 			else {
# 				print "delete_value() 3 -> string not found, in an array\n";
# 				for (my $i=$#stack; $i >= $#stack - 10; $i--) {
# 					print $stack[$i]->{"type","value"};
# 					print "$stack[$i]->{type}\t$stack[$i]->{value}";
# 				}
# 				exit;
# 			}
			1;
		}
		return;
	}
	elsif ($value_type eq "true" || $value_type eq "false" || $value_type eq "null" || $value_type eq "number") {
		if ($stack[-1]->{type} eq $value_type) {
# 			print "\@poped 5 $stack[-1]->{type}\t$stack[-1]->{value}\n";
			pop @stack;
		}
		else {
			print "delete_value() 0 -> $value_type not found\n";
			exit;
		}
		if ($container eq "object") {
			if ($stack[-1]->{type} eq "colon") {
# 				print "\@poped 6 $stack[-1]->{type}\t$stack[-1]->{value}\n";
				pop @stack;									# delete colon
			}
			else {
				print "delete_value() 1 -> value doesn't have a colon before, in an object\n";
				print "-1 $stack[-1]->{type}\t$stack[-1]->{value}";
				exit;
			}
			if ($stack[-1]->{type} eq "string") {
# 				print "\@poped 7 $stack[-1]->{type}\t$stack[-1]->{value}\n";
				pop @stack;									# delete key
			}
			else {
				print "delete_value() 2 -> value doesn't have a key before, in an object\n";
				exit;
			}
		}
		return;
	}

	while ($stack[-1]->{type} ne $opening_token) {
# 		print "\@poped 8 $stack[-1]->{type}\t$stack[-1]->{value}\n";
		pop @stack;
	}
	if ($stack[-1]->{type} eq $opening_token) {
# 		print "\@poped 9 $stack[-1]->{type}\t$stack[-1]->{value}\n";
		pop @stack;
	}
	else {
		print "delete_value() 4 -> could not found $opening_token\n";
		exit;
	}
	

	if ($container eq "array") {	# ["value",{"key":"value"}]
	# if it is the value of an array, just delete this array
	# already done in the while loop above
# 		print uc "container = array\n";
		return;
	}
	elsif ($container eq "object") {
	# if it is the value of a key/value pair, just delete the key/value pair
# 		print uc "container = object\n";
		if ($stack[-1]->{type} eq "colon") {
# 			print "\@poped 10 $stack[-1]->{type}\t$stack[-1]->{value}\n";
			pop @stack;									# delete colon
		}
		else {
			local $\="\n";
			print "delete_value() 5 -> value doesn't have a colon before\n";
			print scalar @stack;
			for (my $i=0; $i<=$#stack; $i++) {
				print " $i $stack[$i]->{type}\t$stack[$i]->{value}";
			}
			exit;
		}
		if ($stack[-1]->{type} eq "string") {
# 			print "\@poped 11 $stack[-1]->{type}\t$stack[-1]->{value}\n";
			pop @stack;									# delete key
		}
		else {
# 			print "delete_value() 6 -> colon value doesn't have a string before, in an $value_type\n";
			print "delete_value() 6 -> colon value doesn't have a string before\n";
			exit;
		}
		# PLUS delete following comma if any
	}
	# or this could be the root object
	# if root object -> end of processing
}



while (<STDIN>) {
	($token, $value) = split /\s+/, $_, 2;
	chomp $value;
# 	print;

	if    ($token eq "curly_open")   { push @stack, {type => "curly_open",  value => $value} }
	elsif ($token eq "square_open")  { push @stack, {type => "square_open", value => $value} }
	elsif ($token eq "colon")        { push @stack, {type => "colon",       value => $value} }
	elsif ($token eq "comma")        { push @stack, {type => "comma",       value => $value} #}
										unless $stack[-1]->{type} eq "comma"			# unless values have been deleted
										    or $stack[-1]->{type} eq "curly_open"
										    or $stack[-1]->{type} eq "square_open" }
	# UNLESS --> for when the (key/) value just before has been deleted

# 	elsif ($token eq "whitespace")   { 1; }		# whitespace ignored by tokenizer

	elsif ($token eq "curly_close")  {
		delete_value("object", innermost_container("object") );
		# delete everything until, and including, the matching "{"
		# plus string and colon directly before if in an object
	}
	elsif ($token eq "square_close") {
		delete_value("array", innermost_container("array") );
		# delete everything until, and including, the matching "["
		# plus string and colon directly before if in an object
	}

	# TERMINAL VALUES

	elsif ($token eq "true") {
		push @stack, {type => "true", value => "true"};
		push @paths, [@stack];
		delete_value("true", innermost_container() );
	}
	elsif ($token eq "false") {
		push @stack, {type => "false", value => "false"};
		push @paths, [@stack];
		delete_value("false", innermost_container() );
	}
	elsif ($token eq "null") {
		push @stack, {type => "null", value => "null"};
		push @paths, [@stack];
		delete_value("null", innermost_container() );
	}
	elsif ($token eq "number") {
		push @stack, {type => "number", value => $value};
		push @paths, [@stack];
		delete_value("number", innermost_container() );
	}
	elsif ($token eq "string") {
		push @stack, {type => "string", value => $value};
		$container = innermost_container();
		
		if (is_string_a_terminal_value($container) ) {	# if not, then it is the key of a k/v pair
			push @paths, [@stack];
			# if not first k/v in object or not first str in array , leave the comma before
			delete_value("string", $container );	
		}
	}
	
}

my @path;
$\="\n";

foreach my $branch (@paths) {
	@path = ();
	foreach ($branch->@*) {
		push @path, $_->{value} unless $_->{type} eq "colon";
	}
	print join "->", @path;
}

__END__

./json_tokenizer.pl avril.json  | ./json_grep2.pl | wc


./json_tokenizer.pl avril.json  | perl -e '@lines=<>; for($i=0; $i < @lines;$i++){ if($lines[$i]=~/^colon/){splice @lines,--$i,1} } print @lines' | perl -ne 'print unless m#^(?:curly|square|colon|comma)#' | wc










