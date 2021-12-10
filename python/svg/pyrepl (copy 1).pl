#!/usr/bin/perl

# this script requires this line in /etc/fstab :
#tmpfs   /tmp/ram/   tmpfs    defaults,noatime,nosuid,nodev,mode=1777,size=32M 0 0
# OR
# mkdir -p /tmp/ram; sudo mount -t tmpfs -o size=32M tmpfs /tmp/ram/

use strict;
use warnings;
use autodie;

my $input;
my @import;
my $oneliner;
my $char;
my $indent_level=0;
my $indent_size=4;
my $line;
local $/=undef;
local $\="";

if (@ARGV) {
	if ($ARGV[0] =~ m/^-I/) {
		$ARGV[0] =~ s/^-I//;
		@import = split /,/, $ARGV[0];
		shift;
	}
}

if (@ARGV) {
	if (-e $ARGV[0]) { $input = <ARGV>  }
	else             { $input = $ARGV[0]}
}
elsif (not -t STDIN) { $input = <STDIN> }
else                 {exit}

#print $input, "\n";

shift @ARGV;
my $args = join " ", @ARGV;
#print $args;
#exit;

open my $program, "+<", \$oneliner;
#print $program $ARGV[0];
print $program $input;
seek $program, 0, 0;

my $python_script = "/tmp/ram/python_script.py";	# requires mounting tmpfs
#my $python_script = "./.python_script.py";

#open my $SCRIPT, ">&", \*STDOUT;
open my $SCRIPT, ">", $python_script;
foreach (@import){
	print $SCRIPT "import $_\n";
}

print $SCRIPT "\n";

while(not eof $program) {
	$line = "";

	# to improve :
	# recognize if ';' '{' or '}' are tokens or only characters in a string

	while (read($program, $char, 1), ($char ne ";") and ($char ne "{") and ($char ne "}") and (not eof $program)) {
		next if $char eq " " and $line eq "";	# stip spaces at the begining of an instruction
												# like in pyrepl 'var=5; print(var)' (space before print)
		$line .= $char;
	}
	
	if ($char eq ";") {
		print $SCRIPT " " x ($indent_level * $indent_size) . $line . "\n";
	}
	elsif ($char eq "{") {
		print $SCRIPT " " x ($indent_level * $indent_size) . $line . " :\n";
		$indent_level++;
	}
	elsif ($char eq "}") {
		print $SCRIPT " " x ($indent_level * $indent_size) . $line . "\n\n";
		$indent_level--;
	}
	else {
		$line .= $char;
		print $SCRIPT " " x ($indent_level * $indent_size) . $line . "\n";
	}
}

die "unmatched curly bracket\n" if $indent_level != 0;

print $SCRIPT "\n";

close $program;
close $SCRIPT;

#open $SCRIPT, "<", $python_script;
#print <$SCRIPT>;
#close $SCRIPT;
#exit;

#system "python $python_script";
#system "python $python_script", $args;
#system "python", "$python_script", $args;
#system "python", $python_script, $args;
system "python", $python_script, @ARGV;

unlink $python_script;


