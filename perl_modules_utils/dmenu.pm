
# unicode ??
# XS version / PP version ?
# quotemeta args ?
# allow passing arrayref as second argument
# make a package and include in it the (modified) source code of dmenu ?


package dmenu;

use strict;
use warnings;

# perl -le 'use dmenu; print dmenu("-i -l 30", `ls`)'
# perl -le 'use dmenu "coderef"; $dmenu=dmenu->new; print $dmenu->("-i -l 30", `ls`)'


sub import {
    if ($_[1] && $_[1] eq "coderef") {
    }
    else {
        no strict 'refs';
        my $caller = caller;

        if ( ! exists &{ $caller . "::dmenu" } ) {
            *{ $caller . "::dmenu" } = \&{"dmenu::dmenu"};
        }
    }
}

sub new {
    return \&dmenu;
}

# using pipe, fork and exec manully is slightly faster than using IPC::Open2

sub dmenu {
	my $args = shift; # --> "-i -l 30" or ["-i -l 30"] or ["-i -l 30", "utf8"]
	pipe my ($DMENU_READ, $PERL_WRITE);
	pipe my ($PERL_READ, $DMENU_WRITE);

	if(!(my $pid=fork)) {
		# dmenu process
		close $PERL_READ;
		close $PERL_WRITE;

        # use $IN and $OUT ????
		close STDIN;
		open STDIN, "<&", $DMENU_READ;
# 		open STDIN, "<&:encoding(UTF-8)", $DMENU_READ;

		close STDOUT;
		open STDOUT, ">&", $DMENU_WRITE;
# 		open STDOUT, ">&:encoding(UTF-8)", $DMENU_WRITE;

		exec "dmenu $args"; # ex :  $args = "-i -l 30"
# 		exec "dmenu $args -fn '-xos4-terminus-medium-r-*-*-10-*'";
	} else {
		close $DMENU_READ;
		close $DMENU_WRITE;
        # avoid error message when pressing Escape in dmenu and making no selection
        open my $stderr, ">&", STDERR;
		close STDERR;
		
#         binmode STDOUT, ":encoding(UTF-8)";
# 		print $PERL_WRITE map { s/\t/    /gr } @_;   # tabs make dmenu slow
		print $PERL_WRITE join "\n", map { chomp; s/\t/    /gr } @_;   # tabs make dmenu slow


		close $PERL_WRITE;
#         wait;
#         my $res = $?;
# 
#         print $!;
#         print $^E;
#         print $@;
#         print $res;
#         print $res >> 8;
#         print $res & 127;
#         print $res & 128;



		if (wantarray) {
			chomp (my @receive = <$PERL_READ>);
			close $PERL_READ;
            open STDERR, ">&", $stderr;
#             print "before return, wantarray";
			return @receive;
		}
		else {
			chomp (my $receive = <$PERL_READ>);
#             my $err = $?; print $err;
#             my $err = $!; print $err;
#             my $err = $@; print $err;
#             my $err = $^E; print $err;
			close $PERL_READ;
            open STDERR, ">&", $stderr;
#             print "before return, else";
			return $receive;
		}
	}
}


1;


