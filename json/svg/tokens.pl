#!/usr/bin/perl

use strict;
use warnings;



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

	if   ($json =~ m/\G  \{    /gscx) 
	elsif($json =~ m/\G  \}    /gscx) 
	elsif($json =~ m/\G  \[    /gscx) 
	elsif($json =~ m/\G  \]    /gscx) 
	elsif($json =~ m/\G   ,    /gscx) 
	elsif($json =~ m/\G   :    /gscx) 
	elsif($json =~ m/\G  true  /gscx) 
	elsif($json =~ m/\G  false /gscx) 
	elsif($json =~ m/\G  null  /gscx) 

	elsif($json =~ m/\G( [ \n\r\t]*)/gsc) 


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






my $json;

if (@*ARGS) {
	if (@*ARGS[0].IO.e) { $json = @*ARGS[0].IO.slurp }
	else                { $json = @*ARGS[0]}
}
elsif (not $*IN.t)      { $json = $*IN.slurp }
else                    { exit }


my $end = 0;
#my @tokens;


my regex curly_open   {    \{    }
my regex curly_close  {    \}    }
my regex square_open  {    \[    }
my regex square_close {    \]    }
my regex comma        {    ','    }
my regex colon        {    ':'    }
my regex true         {  'true'  }
my regex false        {  'false' }
my regex null         {  'null'  }
my regex whitespace   {:s <[ \n\r\t]>* }

my regex string {	\"	
						[			
							   <[^"\\]>
						|   [ '\\' <["\\/bfnrt]> | '\u' <[0..9a..fA..F]>**4 ]

						]
					\"
				}

my regex number {	<[-]>?		[ 0 | <[1..9]> <[0..9]>* ]
								[ \. <[0..9]>+  ]?				# fraction
								[ <[eE]> <[-+]>? <[0..9]>+ ]?	# exponent
				}


#while not $end {
#
#	if $json ~~ / ^ <curly_open> / { say "curly_open"; $json ~~ s|^$/.Str||   }
#	if $json ~~ / ^ <curly_open> / { say "curly_open"; $json ~~ s|^$/.Str||   }
#	if $json ~~ / ^ <curly_open> / { say "curly_open"; $json ~~ s|^$/.Str||   }
#	if $json ~~ / ^ <curly_open> / { say "curly_open"; $json ~~ s|^$/.Str||   }
#	if $json ~~ / ^ <curly_open> / { say "curly_open"; $json ~~ s|^$/.Str||   }
#	if $json ~~ / ^ <curly_open> / { say "curly_open"; $json ~~ s|^$/.Str||   }
#	if $json ~~ / ^ <curly_open> / { say "curly_open"; $json ~~ s|^$/.Str||   }
#	if $json ~~ / ^ <curly_open> / { say "curly_open"; $json ~~ s|^$/.Str||   }
#	if $json ~~ / ^ <curly_open> / { say "curly_open"; $json ~~ s|^$/.Str||   }
#	if $json ~~ / ^ <curly_open> / { say "curly_open"; $json ~~ s|^$/.Str||   }
#	if $json ~~ / ^ <curly_open> / { say "curly_open"; $json ~~ s|^$/.Str||   }
#
#
#
#}





$json ~~ / 

^ [ :r <curly_open> | <curly_close> | <square_open> | <square_close>
	| <comma> | <colon> | <true> | <false> | <null> | <whitespace> | <number> | <string> ]* $ /;



=begin END

#$\="\n";
#print "$_->{type}\t$_->{value}" foreach @tokens;

printf "%-20s %s\n", $_->{type}, $_->{value} foreach @tokens;

__END__

array :  '['  whitespace |  value ( ',' value )*  ']'


value :  whitespace  (string | number | object | array | true | false | null) whitespace


object : '{'  whitespace |       whitespace string whitespace ':' value  
                           (','  whitespace string whitespace ':' value )*   '}'




semantically, terminal elements are string, number, true, false, null



=end END

