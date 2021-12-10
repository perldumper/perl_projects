#!/usr/bin/perl6

use v6;

# https://www.json.org/json-en.html

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

#^ [ :r <curly_open> || <curly_close> || <square_open> || <square_close>
^ [ <curly_open> || <curly_close> || <square_open> || <square_close>
	|| <comma> || <colon> || <true> || <false> || <null> || <whitespace> || <number> || <string> ]* $ /;



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

