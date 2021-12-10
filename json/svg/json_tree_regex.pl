#!/usr/bin/perl

# https://www.json.org/json-en.html

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

my $regex = qr%


(?(DEFINE)

	(?<curly_open>\{) 
	(?<curly_close>\})
	(?<square_open>\[) 
	(?<square_close>\]) 
	(?<comma>,) 
	(?<colon>:) 
	(?<true>true) 
	(?<false>false) 
	(?<null>null) 
	(?<whitespace>[ \n\r\t]*)
	(?<string>(\"	
				(?:			
					   [^"\\]
				|   (?: \\["\\/bfnrt] | \\u[0-9a-fA-F]{4} )

				)*
							\"
		      )
	)
	(?<number>(  [-]?	(?: 0 | [1-9] [0-9]* ) 
								(?: \. [0-9]+  )?			(?# fraction)
								(?: [eE] [-+]? [0-9]+ )?	(?# exponent)
		      )
	)


	(?<TOP> (?&object) | (?&array) )

	(?<array> (?&square_open) (?:  (?&whitespace) | (?&value) (?: (?&comma) (?&value) )* )  (?&square_close) )

	(?<value> (?&whitespace)  (?: (?&string) | (?&number) | (?&object) | (?&array) | (?&true) | (?&false) | (?&null) ) (?&whitespace) )

	(?<object> (?&curly_open) (?:  (?&whitespace) | (?&whitespace) (?&string) (?&whitespace) (?&colon) (?&value)  (? (?&comma)  (?&whitespace) (?&string) (?&whitespace) (?&colon) (?&value) )* )  (?&curly_close)  )


)
	^   (?&TOP)   $
%x;


print "match" if $json =~ $regex;

__END__


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

#$\="\n";
#print "$_->{type}\t$_->{value}" foreach @tokens;

printf "%-20s %s\n", $_->{type}, $_->{value} foreach @tokens;

__END__

array :  '['  whitespace |  value ( ',' value )*  ']'

value :  whitespace  (string | number | object | array | true | false | null) whitespace

object : '{'  whitespace |       whitespace string whitespace ':' value  
                           (','  whitespace string whitespace ':' value )*   '}'




semantically, terminal elements are string, number, true, false, null





