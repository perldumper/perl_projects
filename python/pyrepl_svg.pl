#!/usr/bin/perl

use strict;
use warnings;


############
#   BUGS   #
############

#  pyrepl 'for i in iter([1,2,3,4,5]) {print(i)}'
# Use of uninitialized value $cli_commands in numeric eq (==) at /home/london/.my_configurations/scripts/perl/repl/pyrl.pl line 106.


# $ pyrepl debug -e 'class Color() {}'
# Traceback (most recent call last):
#   File "<string>", line 1, in <module>
#   File "<string>", line 3
# 
#     ^
# IndentationError: expected an indented block
# ----------------------------------------
# WHITESPACE EQUIVALENT
# class Color()  :
# 
# 
# ----------------------------------------
# COMMAND
# python -c 'exec("class Color()  :\n    \n\n")'
# london@archlinux:~
# $ pyrepl debug -e 'class Color() {}'



# london@archlinux:~
# $ pyrepl -Isys,os -e 'if len(sys.argv) > 1 { if os.path.isfile(sys.argv[1]) { for _ in open(sys.argv[1]).readlines() { print(_,end="")
# } } } elif { print "no argv" }' wd
# Traceback (most recent call last):
#   File "<string>", line 1, in <module>
#   File "<string>", line 13
#     elif  :
#           ^
# SyntaxError: invalid syntax
# london@archlinux:~
# $ pyrepl -Isys,os -e 'if len(sys.argv) > 1 { if os.path.isfile(sys.argv[1]) { for _ in open(sys.argv[1]).readlines() { print(_,end="")
# } } } elif { print("no argv") }' wd
# Traceback (most recent call last):
#   File "<string>", line 1, in <module>
#   File "<string>", line 13
#     elif  :
#           ^
# SyntaxError: invalid syntax
# london@archlinux:~
# $ pyrepl -Isys,os -e 'if len(sys.argv) > 1 { if os.path.isfile(sys.argv[1]) { for _ in open(sys.argv[1]).readlines() { print(_,end="")
# } } } elif { print("no argv") }' wd




#################################

my $debug = 0;		# if true, dumps the correctly whitespaced file produced
my $p_switch = 0;
my $l_switch = 0;
my $a_switch = 0;
my $n_switch = 0;
my $s_switch = 0;
my $i_switch = 0;

#input
my $cli_commands;	# commands directly passed as @ARGV to pyrepl
my @import;			# list of imported modules

#output
my $script;			# syntactically correct python code produced, will be passed to python -c 'exec()'

# temporary storage
my $input;			# copy of cli_commands, used as an in-memory file
my $char;
my $line = "";
my @BEGIN;		# contain BEGIN blocks
my @END;		# contain END blocks

# whitespace
my $indent_level = 0;
my $indent_size  = 4;	# number of spaces in one identation level

# finite automata state
my $paren_level;	# counter for finding matching closing parenthesis
my $list_level;		# counter for finding matching closing bracket
my $object_level;	# counter for finding matching closing curly bracket
my $end_of_string;

$/=undef;
$\="";

# def add(a,b) { return a+b }
# for i in [1,2,3,4,5] { print(i) }
# if var == "text" { print("true") }

sub usage {
print STDERR <<'EOF';
  usage :     pyrepl [debug] [-Imodule1[,module2[,..]]] 'COMMANDS'

  COMMANDS ex : 'var=4; for i in [1,2,3,4,5] { if var == i { print(f"found {var} in list") } }'
	pyrepl -Ire,sys 'for word in re.split("\s+", open(sys.argv[1]).read()) { print(word) }' wd
EOF
}

if (@ARGV) {
	if (-e $ARGV[0]) {
		$cli_commands = <ARGV>
	}
	else {
		ARGUMENT:
		while (my $arg = shift @ARGV) {
			if ($arg =~ /^-{0,2}debug$/) {
				$debug = 1;
			}
			elsif ($arg =~ /^-I/) {
				$arg =~ s/^-I//;
				@import = split /,/, $arg;
			}
			elsif ($arg =~ /^-M/) {
				$arg =~ s/^-M//;
				@import = split /,/, $arg;
			}
			elsif ($arg =~ /^-F/) {
				$arg =~ s/^-F//;
			}
			elsif ($arg =~ /^-[planesi]+/) {
				$arg =~ s/^-//;
				foreach my $switch (split //, $arg) {
					if ($switch eq "e") {
						$cli_commands = shift @ARGV;
						last ARGUMENT;					# keep the rest of @ARGV
					}
					elsif ($switch eq "l") {
						$l_switch = 1;
					}
					elsif ($switch eq "p") {
						$p_switch = 1;
					}
					elsif ($switch eq "n") {
						$n_switch = 1;
					}
					elsif ($switch eq "a") {
						$a_switch = 1;
					}
					elsif ($switch eq "s") {
						$s_switch = 1;
					}
					elsif ($switch eq "i") {
						$i_switch = 1;
					}
					else {
						die "unrecognized switch \"$switch\"\n";
					}
				}
			} # elsif -[planesi]+
			else {
				die "Can't open python file $arg\n";
			}
		} # while
	} # else, not -e $ARGV[0]
} # if @ARGV
elsif (not -t STDIN) {
	$cli_commands = <STDIN>
}
else { usage(); exit }


# exit unless $input;
$cli_commands = " " if length $cli_commands == 0;

sub get_single_quoted_string {
	my $char;
	my $string = "";
	$end_of_string = 0;
	while (not $end_of_string) {
		while ( read(INPUT, $char, 1), $char ne "'" and $char ne "\\" and not eof INPUT ) {
			$string .= $char;
		}
		if ($char eq "'") {
			$string .= $char;
			$end_of_string = 1;
		}
		elsif ($char eq "\\") {
			$string .= $char;
			read(INPUT, $char, 1);
			$string .= $char;
		}
		else {	# eof INPUT
			$string .= $char;
			$end_of_string = 1;
		}
	}
	return $string
}

sub get_double_quoted_string {
	my $char;
	my $string = "";
	$end_of_string = 0;
	while (not $end_of_string) {
		# end of file necessary only in the case of incorrect syntax like: print("this is\\" text")
		while ( read(INPUT, $char, 1), $char ne "\"" and $char ne "\\" and not eof INPUT ) {
			$string .= $char;
		}
		if ($char eq "\"") {
			$string .= $char;
			$end_of_string = 1;
		}
		elsif ($char eq "\\") {
			$string .= $char;
			read(INPUT, $char, 1);
			$string .= $char;
		}
		else { 	# eof INPUT
			$string .= $char;
			$end_of_string = 1;
		}
	}
	return $string
}


sub get_block {
	my $char;
	my $block = "";
	$object_level = 1;
	while ($object_level > 0 and not eof INPUT) {
		read INPUT, $char, 1;
		$block .= $char;
		if ($char eq "\"") {
			$block .= get_double_quoted_string();
# 			print "BLOCK $block";
		}
		elsif ($char eq "'") {
			$block .= get_single_quoted_string();
		}
		elsif ($char eq "{") {
			$object_level++;
		}
		elsif ($char eq "}") {
			$object_level--;
		}
	}
	chop $block;	# remove final '}'
# 	return $block;
	return $block =~ s/^\s+//r;
}

# store the $input into an in-memory file (the scalar variable $oneliner)
# which allow to read one character at a time using a filehandle, using "read"
open INPUT, "+<", \$input;
print INPUT $cli_commands;
seek INPUT, 0, 0;

open SCRIPT_FILE, ">", \$script;

foreach (@import) {
	print SCRIPT_FILE "import $_\n";
}
print SCRIPT_FILE "\n"
	if @import and not $n_switch and not $p_switch;		# avoid empty line between 2 import

# blocks
# BEGIN {} END {}


# file handles
# <STDIN> <ARGV>   stdin.read() stdin.readline() stdin.readlines(), same with argv ?
# implement those as objects ? (so that lines read are consumed)

# special variables
# @ARGV
# @F
# $/
# $\ $, $"
# $.
# $_
# $` $& $'
# $+ %+ %- @+ @-
# $| ??

# operators
# =~
# .

# control flow
# next redo ??

# functions to port
# chomp
# m s tr/y
# m()    m as a function
# _.m    m as a method --> implementation =
#	 		create a class for scalar variables, and make that all variables are instances of this class ?

# implied $_
# print(), end="" / end=$\ also always given as argument, unless end is dirctly passed
# or
# end only always given if $\ is set

if (@BEGIN) {
}


if ($p_switch) {
	print SCRIPT_FILE "import sys\n" unless grep {$_ eq "sys"} @import;
	print SCRIPT_FILE "import os\n"  unless grep {$_ eq "os" } @import;
	print SCRIPT_FILE "\n";

	print SCRIPT_FILE "if len(sys.argv) > 1 :\n";
	print SCRIPT_FILE " " x (1 * $indent_size) . "if os.path.isfile(sys.argv[1]) :\n";
	print SCRIPT_FILE " " x (2 * $indent_size) . "_main_loop = open(sys.argv[1])\n";
	print SCRIPT_FILE "else :\n";
	print SCRIPT_FILE " " x (1 * $indent_size) . "_main_loop=sys.stdin\n\n";
	print SCRIPT_FILE "for _ in _main_loop.readlines() :\n";
	$indent_level++;
}
elsif ($n_switch) {
	print SCRIPT_FILE "import sys\n" unless grep {$_ eq "sys"} @import;
	print SCRIPT_FILE "import os\n"  unless grep {$_ eq "os" } @import;
	print SCRIPT_FILE "\n";

	print SCRIPT_FILE "if len(sys.argv) > 1 :\n";
	print SCRIPT_FILE " " x (1 * $indent_size) . "if os.path.isfile(sys.argv[1]) :\n";
	print SCRIPT_FILE " " x (2 * $indent_size) . "_main_loop = open(sys.argv[1])\n";
	print SCRIPT_FILE "else :\n";
	print SCRIPT_FILE " " x (1 * $indent_size) . "_main_loop=sys.stdin\n\n";
	print SCRIPT_FILE "for _ in _main_loop.readlines() :\n";
	$indent_level++;
}
elsif ($l_switch) {
}
elsif ($a_switch) {
}
elsif ($s_switch) {
}


# add correct indentation for classes ?
# if empty block --> put 1 ??? or ... or pass

while (not eof INPUT) {

	while (		read(INPUT, $char, 1),
			($char ne ";")	# end of instruction
		and ($char ne "{")	# block start
		and ($char ne "}")	# block end
		and ($char ne "(")	# function or method or tupple start
		and ($char ne "[")	# list start
		and ($char ne "=")	# assignment (in case an dict or a set is assigned to a variable)
		and (not eof INPUT)
	)
	{
		next if $char eq " " and $line eq "";	# stip spaces at the begining of an instruction
												# like in pyrepl 'var=5; print(var)' (space before print)
		$line .= $char;
	}
	
	# END OF INSTRUCTION
	if ($char eq ";") {
		print SCRIPT_FILE " " x ($indent_level * $indent_size) . $line . "\n";
		$line = "";
	}

	# BLOCK START (if, for, while)
	elsif ($char eq "{") {
		if ( $line =~ /BEGIN\s*$/ ) {
# 			print "INSIDE BEGIN {}\n";
# 			print SCRIPT_FILE " " x ($indent_level * $indent_size) . $line . " :\n";
# 			print "GET BLOCK \"", get_block(), "\"\n\n";
# 			push @BEGIN, correctly_whitespaced(get_block());
			get_block();
# 			$indent_level++;
			$line = "";
			
		}
		elsif ( $line =~ /END\s*$/ ) {
# 			print "INSIDE END {}\n";
# 			print SCRIPT_FILE " " x ($indent_level * $indent_size) . $line . " :\n";
			$indent_level++;
			$line = "";
		}
		else {
			print SCRIPT_FILE " " x ($indent_level * $indent_size) . $line . " :\n";
			$indent_level++;
			$line = "";
		}
	}

	# BLOCK END (if, for, while)
	elsif ($char eq "}") {		# detect empty block ???
		print SCRIPT_FILE " " x ($indent_level * $indent_size) . $line . "\n\n";
		$indent_level--;
		$line = "";
	}

# python -c 'print("hello")'
# python -c 'print ("hello")'


	# FUNCTION OR METHOD OR TUPPLE START
	elsif ($char eq "(") {
		$paren_level = 1;
		$line .= $char;
# 		while ($paren_level > 0) {
		while ($paren_level > 0 and not eof INPUT) {
			read INPUT, $char, 1;
			$line .= $char;
			if ($char eq "\"") {
				$line .= get_double_quoted_string();
			}
			elsif ($char eq "'") {
				$line .= get_single_quoted_string();
			}
			elsif ($char eq "(") {
				$paren_level++;
			}
			elsif ($char eq ")") {
				$paren_level--;
			}
		}
	}

	# LIST START (for i in [1,2,3,4,5])
	elsif ($char eq "[") {
		$list_level = 1;
		$line .= $char;
		while ($list_level > 0 and not eof INPUT) {
			read INPUT, $char, 1;
			$line .= $char;
			if ($char eq "\"") {
				$line .= get_double_quoted_string();
			}
			elsif ($char eq "'") {
				$line .= get_single_quoted_string();
			}
			elsif ($char eq "[") {
				$list_level++;
			}
			elsif ($char eq "]") {
				$list_level--;
			}
		}
	}

	# ASSIGNMENT
	elsif ($char eq "=") {
		$line .= $char;
		while( read(INPUT, $char, 1), $char eq " " and not eof INPUT) {
			$line .= $char;
		}
		# DICT OR SET ASSIGNMENT
		if ($char eq "{") {
			$line .= $char;
			$object_level = 1;
			while ($object_level > 0 and not eof INPUT) {
				read INPUT, $char, 1;
				$line .= $char;
				if ($char eq "\"") {
					$line .= get_double_quoted_string();
				}
				elsif ($char eq "'") {
					$line .= get_single_quoted_string();
				}
				elsif ($char eq "{") {
					$object_level++;
				}
				elsif ($char eq "}") {
					$object_level--;
				}
			}
		}
		# LIST ASSIGNMENT
		elsif ($char eq "[") {
			$line .= $char;
			$list_level = 1;
			while ($list_level > 0 and not eof INPUT) {
				read INPUT, $char, 1;
				$line .= $char;
				if ($char eq "\"") {
					$line .= get_double_quoted_string();
				}
				elsif ($char eq "'") {
					$line .= get_single_quoted_string();
				}
				elsif ($char eq "[") {
					$list_level++;
				}
				elsif ($char eq "]") {
					$list_level--;
				}
			}
		}

		# SINGLE QUOTED STRING assignment
		elsif ($char eq "'") {
			$line .= $char;
			$line .= get_single_quoted_string();
		}

		# DOUBLE QUOTED STRING assignment
		elsif ($char eq "\"") {
			$line .= $char;
			$line .= get_double_quoted_string();
		}

		# EOF or bare NUMBER or python BUILT-IN CONSTANTS (True, False, None, NotImplemented, Ellipsis, ..., __debug__, etc..)
		else {
			$line .= $char;
			# the following characters of the assignment continue to be appended on the next loop iteration
		}
	}

	# END OF FILE
	else {
		$line .= $char;
		print SCRIPT_FILE " " x ($indent_level * $indent_size) . $line . "\n";
		$line = "";
	}
}

# $script = correctly_whitespaced($cli_commands);	# $cli_program


# final flush
if ($line ne "") {	# case when program finishes after "]" or ")" but no trailing ";" on the last instruction
	print SCRIPT_FILE " " x ($indent_level * $indent_size) . $line . "\n";
}

if ($p_switch) {
	print SCRIPT_FILE " " x ($indent_level * $indent_size) . 'print(_, end="")' . "\n";
	$indent_level--;
}

if (@END) {
}


close INPUT;
close SCRIPT_FILE;

die   "unmatched curly bracket\n" if $indent_level != 0 and not $debug;
print "unmatched curly bracket\n" if $indent_level != 0 and $debug;

my $exec = "exec(\""
          . $script =~ s/\\/\\\\/gr =~ s/\n/\\n/gr =~ s/"/\\"/gr
          . "\")";

system "python", "-c", $exec, @ARGV;

if ($debug) {
	print "-" x 40, "\n";
	print "WHITESPACE EQUIVALENT\n";
	print $script =~ s/\\n/\n/gr;
	print "-" x 40, "\n";
	print "COMMAND\n";
	print "python -c \'$exec\'\n";
}






