#!/usr/bin/perl

# this script requires this line in /etc/fstab :
# tmpfs   /tmp/ram/   tmpfs    defaults,noatime,nosuid,nodev,mode=1777,size=32M 0 0
# OR
# mkdir -p /tmp/ram; sudo mount -t tmpfs -o size=32M tmpfs /tmp/ram/

use strict;
use warnings;
use autodie;

# EXAMPLE
# crepl -Istdio 'printf("hello\n");'

my @include;			# list of #include <library.h>
my @compile_flags;		# -E -l/usr/lib/ etc..
my $input;
my $debug = 0;
my $only_headers = 0;	# output of cpp / gcc -E

sub uniq {
    my %seen;
    grep { !$seen{$_}++ } @_
}

for (1) {
	if (@ARGV) {
		if ($ARGV[0] =~ m/^-I/) {
			$ARGV[0] =~ s/^-I//;
			push @include, map { s/\.h$//r } split /,/, shift;
			redo;
		}
		elsif ($ARGV[0] =~ m/^-l/) {
			push @compile_flags, shift;
			redo;
		}
		elsif ($ARGV[0] =~ m/^-{1,2}gcc$/) {
            shift;
			push @compile_flags, shift;
			redo;
		}
		elsif ($ARGV[0] eq "-E") {
			$only_headers = 1;
			shift;
			redo;
		}
		elsif ($ARGV[0] =~ /^-{0,2}debug$/) {
			$debug = 1;
			shift;
			redo;
		}
		else {
			last;
		}
	}
}
$/=undef;

if (@ARGV) {
	if (-e $ARGV[0]) { $input = <ARGV>  }
	else             { $input = $ARGV[0]}
}
elsif (not -t STDIN) { $input = <STDIN> }
else                 { exit }

shift @ARGV;

my $source_code   = "/tmp/ram/c_program.c";	# requires mounting tmpfs
my $compiled_code = "/tmp/ram/c_program.o";	# requires mounting tmpfs
# my $source_code   = "./.c_program.c";
# my $compiled_code = "./.c_program.o";

$\="\n";

open my $FH, ">", $source_code;
foreach (uniq @include){
	print $FH "#include <$_.h>";
}
print $FH "";
print $FH "int main(int argc, char *argv[]) {";
print $FH $input;
print $FH "return 0;";
print $FH "}";
close $FH;

if ($debug) {
	open my $FH, "<", $source_code;
	print <$FH>;
	close $FH;
    print join " ", "gcc", @compile_flags, $source_code, "-o", $compiled_code;
}
elsif ($only_headers) {
	print qx{ gcc -E @compile_flags $source_code };
}
else {
	system "gcc", @compile_flags, $source_code, "-o", $compiled_code;
	system $compiled_code, @ARGV;

	my $status = $?;
	if ($status == -1) {
		print "failed to execute: $!\n";
	}
	elsif ($status & 127) {
        # segmentation fault
		printf "child died with signal %d, %s coredump\n",
			($status & 127), ($status & 128) ? 'with' : 'without';
	}
	unlink $source_code, $compiled_code;

}



