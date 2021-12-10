package dd;

use Data::Dumper;
$Data::Dumper::Sortkeys=1;
$Data::Dumper::Indent = 1;
# use DDP;
use v5.10;

sub import {

    shift;
#     require DDP @_;
    require DDP;
#     DDP::import(@_);
#     Data::Printer::import(@_);
    Data::Printer::import({ @_ });
#     use DDP @_;

#     no strict 'refs';
    my $caller = caller;

    foreach my $sub (qw(dd)) {

        if ( ! exists &{ $caller . "::" . $sub } ) {
            *{ $caller . "::" . $sub } = \&{"dd::" . $sub};
        }
    }   

    for my $sub (keys %::DDP::) {

        if ( exists &{ $::DDP::{$sub} } ) {
            if ( ! exists &{ $caller . "::" . $sub } ) {
                *{ $caller . "::" . $sub } = \&{"DDP::" . $sub};
            }
        }
    }
}

sub dd {
	local $\="";	# dumper put already put a newline
	print Dumper @_;
}

1;

