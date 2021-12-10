
package Operations;
use strict;
use warnings;


##########################
#    MATHS OPERATIONS    #
##########################

# my %precedence = ("^" => 3, "*" => 2, "/" => 2, "+" => 1, "-" => 1, "(" => 0, ")" => 0);
# my %precedence = (exp=>0, log=>0, log10=>0, sin=>0, cos=>0, tan=>0, "^" => 3, "*" => 2, "/" => 2, "+" => 1, "-" => 1, "(" => 0, ")" => 0);

our %precedence = (
	exp   => 4,
	ln    => 4,
	log   => 4,
	log10 => 4,
	exp10 => 4,

	sqrt  => 4,
	sin   => 4,
	cos   => 4,
	tan   => 4,
	arcsin => 4,
	arccos => 4,
	arctan => 4,
	pow2   => 4,

	"nth-root" => 3,
	"%"   => 3,		# ???
	"^"   => 3,
	sqrt  => 3,

	"*"   => 2,
	"/"   => 2,

	"+"   => 1,
	"-"   => 1,
	"("   => 0,
	")"   => 0,
	#"("   => 5,
	#")"   => 5,
);

our %left_associative = (
	"*"   => 1,
	"/"   => 1,
	"+"   => 1,
	"-"   => 1,
	"%"   => 1,

	"nth-root" => 0,
	"^"   => 0,
	sqrt  => 0,
	pow2  => 0,

	exp   => 0,
	ln    => 0,
	log   => 0,
	log10 => 0,
	exp10 => 0,

	sin   => 0,
	cos   => 0,
	tan   => 0,
	arcsin   => 0,
	arccos   => 0,
	arctan   => 0,
);

our %right_associative = (
	"*"   => 1,
	"/"   => 0,
	"+"   => 1,
	"-"   => 0,
	"%"   => 0,

	"^"   => 1,
	"nth-root" => 1,
	sqrt  => 1,
	pow2  => 1,

	exp   => 1,
	ln    => 1,
	log   => 1,
	log10 => 1,
	exp10 => 1,

	sin   => 1,
	cos   => 1,
	tan   => 1,
	arcsin   => 1,
	arccos   => 1,
	arctan   => 1,
);

our %inverse = (
	"+"   => "-",
	"-"   => "+",
	"*"   => "/",
	"/"   => "*",
	"%"   => "",		# ??? arithmetic function / algorithm, Euclidean division ?

	"^"   => "nth-root",		# n-root, exponent form ?	# pow 1/n
	"nth-root" => "^",
	pow2  => "sqrt",
	sqrt  => "pow2",

	exp   => "ln",
	ln    => "exp",
	log   => "exp",
	log10 => "exp10",
	exp10 => "log10",

	sin   => "arcsin",
	cos   => "arccos",
	tan   => "arctan",
	arcsin  => "sin",
	arccos  => "cos",
	arctan  => "tan",
);



1;
