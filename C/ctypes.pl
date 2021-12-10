#!/usr/bin/perl

use strict;
use warnings;
exit unless @ARGV;

# IMPLEMENTATION OF :
# http://unixwiz.net/techtips/reading-cdecl.html

# EXAMPLES
# ctypes 'int (*(*foo)())()'
# ctypes 'char *(*(**foo[][8])())[]'

# BUG ???
# london@archlinux:~
# $ ctypes -TSV -TMAGIC 'int (int*)(SV *, MAGIC *)Perl_magic_getarylen'
# C TYPE            = int (int*)(SV *, MAGIC *)Perl_magic_getarylen
# BASIC TYPE        = int
# IDENTIFIER        = Perl_magic_getarylen
# Perl_magic_getarylen * * * int
# Perl_magic_getarylen --> * --> * --> * --> int
# Perl_magic_getarylen is pointer to pointer to pointer to int
# london@archlinux:~


# C89 types ?
my @basic_types = qw(char int short long float double signed unsigned void struct enum union);

my @custom_types;

my $type;
for (1) {
	if (@ARGV) {
		if ($ARGV[0] =~ m/^-T/) {	# typedef(s)
			$ARGV[0] =~ s/^-T//;
			push @custom_types, split /,/, $ARGV[0];
			shift;
			redo;
		}
		else {
			$type = shift;
			last;
		}
	}
}

$\="\n";
$,="\n";
$"=" ";

my $alternation = join "|", @basic_types, @custom_types;

# what if there is several indentifier ? can there be more than one ? (in functions ?)


my ($identifier) = $type =~ m/(?!$alternation) (\b[a-zA-Z_][a-zA-Z0-9_]*\b)/x;

my $offset = index $type, $identifier;
my $before = substr $type, 0, $offset;
my $after = substr $type, $offset + length $identifier;

# basic type in the sense of what type is returned, not in the sense : one of the types of @basic_types
my ($basictype) = $type =~ m/ ^ \s* ( (?:$alternation) 
                                (?:\s+(?:$alternation))* ) /x;

if (not defined $basictype) {
	die "basictype not found\n";
}

print "C TYPE            = $type";
print "BASIC TYPE        = $basictype";
print "IDENTIFIER        = $identifier";

$before =~ s/^\s*$basictype//;
my @before = split //, $before;
my @after = split //, $after;

my @tokens;
my $token;
my $buf;
my $char;
my $paren_level=0;	# getting the parameter list of the prototype of a function declaration

push @tokens, $identifier;


sub go_right {
	$buf = $char;
	if ($char eq "[") {		# array
		while ($char = shift @after) {
			last if $char eq "]";
			$buf .= $char;
		}
		$buf .= $char;
		push @tokens, $buf;
	}
	elsif ($char eq "(") {	# prototype of a function declaration
		# get all the characters until the matching ")", in case there is nested ( ... )
		$paren_level++;
		while ($paren_level > 0) {
			$char = shift @after;
			$buf .= $char;
			if ($char eq "(") {
				$paren_level++;
			}
			elsif ($char eq ")") {
				$paren_level--;
			}
		}
		push @tokens, $buf;
	}
	elsif ($char eq ")") {
		go_left();
	}
}

sub go_left {
	$buf = "";
	if (@before) {
		while ($char = pop @before) {
			last if $char !~ /\s/;
		}
		return unless $char;
# 		$buf .=	 $char;				# UNINITIALIZED VALUE
		if ($char eq "*") {				# UNINITIALIZED VALUE
			push @tokens, "*";
		}
		if (@before) {
			while ($char = pop(@before)) {
				last if $char eq "(";
				if ($char eq "*") {
					push @tokens, "*";
				}
			}
		}
	}
}


while (@before or @after) {
	
	$buf = "";
	if (@after) {
		while ($char = shift @after) {
			last if $char !~ /\s/;
		}
	}
	else {
		go_left();
		next;
	}

	go_right();
}

push @tokens, $basictype;

print "@tokens";

print join " --> ", @tokens;

$\="";

$identifier = shift @tokens;
print "$identifier is ";

while (@tokens > 1) {
	$token = shift @tokens;
	if ($token eq "*") {
		print "pointer to ";
	}
	elsif ($token =~ m/^ \[ \] $ /x) {
		print "array of ";
	}	
	elsif ($token =~ m/^ \[ (.*?) \] $ /x) {
			print "array of $1 ";
	}
	elsif ($token =~ m/^\(/) {
		print "function returning ";
	}
}

$basictype = shift @tokens;
print "$basictype\n";




