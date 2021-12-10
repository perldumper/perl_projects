#!/usr/bin/perl

use strict;
use warnings;
use utf8;  # required ?

my $json;
$/=undef;

if (@ARGV) {
	if (-e $ARGV[0]) { $json = <ARGV>  }
	else             { $json = $ARGV[0]}
}
elsif (not -t STDIN) { $json = <STDIN> }
else                 {exit}

my $end = 0;
my @tokens;

while(not $end){

	if   ($json =~ m/\G  \{    /gscx)     {push @tokens,  {type=> "curly_open",     value=> "{"     } }
	elsif($json =~ m/\G  \}    /gscx)     {push @tokens,  {type=> "curly_close",    value=> "}"     } }
	elsif($json =~ m/\G  \[    /gscx)     {push @tokens,  {type=> "square_open",    value=> "["     } }
	elsif($json =~ m/\G  \]    /gscx)     {push @tokens,  {type=> "square_close",   value=> "]"     } }
	elsif($json =~ m/\G   ,    /gscx)     {push @tokens,  {type=> "comma",          value=> ","     } }
	elsif($json =~ m/\G   :    /gscx)     {push @tokens,  {type=> "colon",          value=> ":"     } }
	elsif($json =~ m/\G  true  /gscx)     {push @tokens,  {type=> "true",           value=> "true"  } }
	elsif($json =~ m/\G  false /gscx)     {push @tokens,  {type=> "false",          value=> "false" } }
	elsif($json =~ m/\G  null  /gscx)     {push @tokens,  {type=> "null",           value=> "null"  } }

	elsif($json =~ m/\G( [ \n\r\t]*)/gsc) {push @tokens,  {type=> "whitespace",     value=>  $1     } }
	#-----------------------------------------------------------------------------
	#	(?: any unicode codepoint except " or \ or control characters )
	#	[^"\\]  ???

	elsif($json =~ m@\G(	\"	
				(?:			
					   [^"\\]
				|   (?: \\["\\/bfnrt] | \\u[0-9a-fA-F]{4} )

				)*
							\"
					)@gscx)         {push @tokens,  {type=>"string",          value=>$1} }
	#-----------------------------------------------------------------------------
	elsif($json =~ m/\G(  [-]?	(?: 0 | [1-9] [0-9]* ) 
								(?: \. [0-9]+  )?			(?# fraction)
								(?: [eE] [-+]? [0-9]+ )?	(?# exponent)

					)/gscx)                {push @tokens, {type=>"number",    value=>$1} }
	#-----------------------------------------------------------------------------
	else {$end = 1}
}

my ($token, $value);

foreach (@tokens){
	($token, $value) = $_->@{"type","value"};
	printf "%-20s %s\n", $token, $value;
}


