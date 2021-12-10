# use List::Util qw(reduce);
# use Capture::Tiny ":all";	# capture
# use Cwd;

# BOLD RED like grep(1)
use constant    RESET => "\e[0m";
use constant     BOLD => "\e[1m";
use constant  REVERSE => "\e[7m";
use constant    BLACK => "\e[30m";
use constant      RED => "\e[31m";
# RED, YELLOW and GREEN for malformed json, like perl6
use constant    GREEN => "\e[32m";
use constant   YELLOW => "\e[33m";
use constant     BLUE => "\e[34m";
use constant  MAGENTA => "\e[35m";
use constant     CYAN => "\e[36m";
use constant  BRIGHT_YELLOW => "\e[93m";

use utf8;

sub qqw;

# sub human {
# 
# 	($c) = (split /\s+/, $a)[4];
# 	($d) = (split /\s+/, $b)[4];
# 
# 	#$c=$a;
# 	#$d=$b;
# 
# 	$letter_c = $c=~tr/[0-9].//rd;
# 	$letter_d = $d=~tr/[0-9].//rd;
# 
# 	$c =~ tr/[A-Z]//d;
# 	$d =~ tr/[A-Z]//d;
# 
# 	$c *= 1024						if uc($letter_c) eq "K";
# 	$c *= (1024*1024)				if uc($letter_c) eq "M";
# 	$c *= (1024*1024*1024)			if uc($letter_c) eq "G";
# 	$c *= (1024*1024*1024*1024)		if uc($letter_c) eq "T";
# 
# 	$d *= 1024						if uc($letter_d) eq "K";
# 	$d *= (1024*1024)				if uc($letter_d) eq "M";
# 	$d *= (1024*1024*1024)			if uc($letter_d) eq "G";
# 	$d *= (1024*1024*1024*102)		if uc($letter_d) eq "T";
# 
# 
# 	#return $c <=> $d;
# 	$c <=> $d;
# }


# sub human2 {
# 
# 		#(($discard)x4,$c)=split /\s+/, $a;
# 		#(($discard)x4,$d)=split /\s+/, $b;
# 	#$c=$a;
# 	#$d=$b;
# 
# 	$letter_c=$c=~tr/[0-9].//rd;
# 	$letter_d=$d=~tr/[0-9].//rd;
# 
# 	$c=~tr/[A-Z]//d;
# 	$d=~tr/[A-Z]//d;
# 
# 	$c *= 1024						if uc($letter_c) eq "K";
# 	$c *= (1024*1024)				if uc($letter_c) eq "M";
# 	$c *= (1024*1024*1024)			if uc($letter_c) eq "G";
# 	$c *= (1024*1024*1024*1024)		if uc($letter_c) eq "T";
# 
# 	$d *= 1024						if uc($letter_d) eq "K";
# 	$d *= (1024*1024)				if uc($letter_d) eq "M";
# 	$d *= (1024*1024*1024)			if uc($letter_d) eq "G";
# 	$d *= (1024*1024*1024*102)		if uc($letter_d) eq "T";
# 
# 
# 	#return $c <=> $d;
# 	$c <=> $d;
# }


sub time_from_sec {

	$time = shift;
	#my $time = $ARGV[0];
	#my ($hr, $min, $sec, $mil);
	
	$time *= 1000;
	
	$hr  = int($time/3600000);
	$min = int(($time-$hr*3600000)/60000);
	$sec = int(($time-$hr*3600000-$min*60000)/1000);
	$mil = ($time-$hr*3600000-$min*60000-1000*$sec);
	
# 	$hr="0".$hr if $hr=~/^\d$/;
# 	$min="0".$min if $min=~/^\d$/;
# 	$sec="0".$sec if $sec=~/^\d$/;
# 	$mil="0".$mil if $mil=~/^\d$/;
# 	$mil="0".$mil if $mil=~/^\d\d$/;

	$hr  = "0" . $hr  if length $hr  == 1;
	$min = "0" . $min if length $min == 1;
	$sec = "0" . $sec if length $sec == 1;
	$mil = "0" . $mil if length $mil == 1;
	$mil = "0" . $mil if length $mil == 2;
	
    return $hr, $min, $sec, $mil;
# 	return "$hr:$min:$sec:$mil";
}

# sub touch { # replicate Unix touch(1)
# 	foreach (@_) {
# 		next unless -e;
# 		open $FH, ">>", "$_";
# 		close $FH;
# 	}
# }

# sub reduce {
# 	my $accumulator = $_[1];
# 	for (my $i=2; $i <= $#_; $i++) {
# 		$accumulator = $_[0]->($accumulator, $_[$i])
# 	}
# 	return $accumulator
# }

my $zip = sub {
    my ($array_a, $array_b)=@_;
    return [ map {
        if (ref $array_a->[$_] eq "ARRAY") {
            [$array_a->[$_]->@*, $array_b->[$_]]
        }
        else {
            [$array_a->[$_], $array_b->[$_]]
        }
    } 0..$array_a->$#*]
};

sub _reduce {
    my $code = shift;
	my $acc = shift;
    while (@_) {
        $acc = $code->($acc, shift);
    }
    return $acc;
}

sub transpose { _reduce $zip, @_ }


# london@archlinux:~
# $ perl -le 'print reduce({$a + $b },3,2,1)'
# Type of arg 1 to main::reduce must be block or
# sub {} (not anonymous hash ({})) at -e line 1,
# near "1)
# "
# Execution of -e aborted due to compilation errors.

sub reduce(&;@) {
	my $code = shift;
	our ($a, $b);
	local ($a, $b);
	$a = shift;
	for $b (grep {defined} @_) {
		$a = $code->();
	}
	return $a;
}

# preserve order, return first occurence
# different behavior than uniq(1)
sub uniq { my %seen; grep { !$seen{$_}++ } @_ }

sub version_sort {	# sort version_sort LIST
	my ($c,$d) = ($a,$b);
	my ($elem_a, $elem_b);
	
	while (1) {
		if ($c =~ m/^\d/) {
			if ($d =~ m/^\d/) {
				($elem_a) = $c =~ m/^(\d+)/;
				($elem_b) = $d =~ m/^(\d+)/;
				if ($elem_a != $elem_b) {
					return $elem_a <=> $elem_b
				}
				else {
					$c =~ s/^\d+//;
					$d =~ s/^\d+//;
				}
			}
			elsif ($d =~ m/^\D/) {
				return -1; # numbers before letters
			}
			elsif (length $d == 0) {
				return 1;	# shortest first
			}
		}
		elsif ($c =~ m/^\D/) {
			if ($d =~ m/^\d/) {
				return 1; # numbers before letters
			}
			elsif ($d =~ m/^\D/) {
				($elem_a) = $c =~ m/^(\D+)/;
				($elem_b) = $d =~ m/^(\D+)/;
				if ($elem_a ne $elem_b) {
					return $elem_a cmp $elem_b
				}
				else {
					$c =~ s/^\D+//;
					$d =~ s/^\D+//;
				}
			}
			elsif (length $d == 0) {
				return 1;	# shortest first
			}
		}
		elsif (length $c == 0) {
			if (length $d == 0) {
				return 0
			}
			else {
				return -1;	# shortest first
			}
		}
	}
}

sub __ {
	local $\="\n";
	print "\n", "-" x 40;
}

sub pick {
# 	ex print roll(10, "a" .. "z")
	my $number_of_picks = shift;
	my @out;
	my $idx;
	while ($number_of_picks > 0 and @_) {
		$idx = int(rand(@_));
		push @out, $_[ $idx ];
		splice @_, $idx, 1;
		$number_of_picks--;
	}
	return @out;
}

sub roll {
# 	ex print roll(10000, 1..6)
	my $number_of_rolls = shift;
	my @out;
	for (1 .. $number_of_rolls) {
		push @out, $_[ int(rand(@_)) ]
	}
	return @out;
}

sub so { $_[0] ?  "true" : "false" }
# BUG
# london@archlinux:~
# $ perl -E 'say so "ab" =~ /^ a (?(DEFINE) (?<ww> (?<= \w)(?= \w)) ) /x'false
# london@archlinux:~
# $ perl -E 'say "true" if "ab" =~ /^ a (?(DEFINE) (?<ww> (?<= \w)(?= \w)) ) /x'
# true
# london@archlinux:~
#

sub max {
	reduce { $a > $b ? $a : $b } grep { defined } @_
}
 
sub min {
	reduce { $a < $b ? $a : $b } grep { defined } @_
}

sub maxlen {
	length reduce { length $a > length $b ? $a : $b } grep { defined } @_
}

sub minlen {
	length reduce { length $a < length $b ? $a : $b } grep { defined } @_
# 	reduce { $a < length $b ? $a : length $b } grep { defined } @_
    # 	doesn't work in the case where the string with the minimum length is the first one
    # 	should remake reduce to accept an initial accumulator
}

sub qs { return "\"@_\"" }

sub qqw {
	my $string;
	while ($_ = shift) {
		$string .= "\"$_\"\n"
	}
# 	chomp $string;
	return $string;
}

sub nl { $, = $_[0] // "\n" }


sub copy {
	require File::Copy;
	goto &File::Copy::copy;
}

sub move {
	require File::Copy;
	goto &File::Copy::move;
}

sub basename {
	require File::Basename;
	goto &File::Basename::basename;
}

sub dirname {
	require File::Basename;
	goto &File::Basename::dirname;
}

sub fileparse {
	require File::Basename;
	goto &File::Basename::fileparse;
}

sub remove_ext {
	$_[0] =~ s/\.[^.]+$//r
}

sub remove_tree {
	require File::Path;
	goto &File::Path::remove_tree;
}

sub slurp {
	my $path = shift;
	local $/ = undef;
	local $\ = "";
	open my $FH, "<", $path or die "Can't open file \"$path\"\n";
# 	open my $FH, "<:encoding(UTF-8)", $path or die "Can't open file \"$path\"\n";
	my $file = <$FH>;
	close $FH;
	return $file;
}

sub spurt {
	my $path = shift;
	local $\ = "\n";
	open my $FH, ">", $path or die "Can't open file \"$path\"\n";
	print $FH @_;
	close $FH;
}

sub find {
	if (@_) {
		map { chomp; $_ } map { $_=quotemeta; `find $_` } @_
	}
	else {
		map { chomp; $_ } `find`
	}
}

sub remove_accents {
	$_[0] =~
    tr/àÀâÂäÄçÇéÉèÈêÊëËîÎïÏôÔöÖùÙûÛüÜÿŸ/aAaAaAcCeEeEeEeEiIiIoOoOuUuUuUyY/r
}

sub ls {
	opendir my $DIR, "./";
	readdir $DIR
}

# replace with the one in download.pm
sub next_available_name {
    my $format = shift; # "string%dstring"
    # check if not %d or other placeholder
    my $idx = 0;

#     opendir my $DIR, "./";
#     my @files = grep { / ^ $format /x } readdir $DIR;
#     close $DIR;
#     while (grep { / ^ $format 0* $idx $ /x } @files) {
#         $idx++;
#     }

    while (-e $format . $idx) {
        $idx++;
    }

    return $format . $idx;
}


1;

__END__

File::Copy


NOTES
Before calling copy() or move() on a filehandle, the caller
should close or flush() the file to avoid writes being lost. Note
that this is the case even for move(), because it may actually
copy the file, depending on the OS-specific implementation, and
the underlying filesystem(s).














1;

