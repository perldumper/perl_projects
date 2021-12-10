
package myparser;

use strict;
use warnings;
use v5.10;

use base qw(HTML::Parser);
use HTML::Entities;

# our @ISA;
# push @ISA, qw(HTML::Parser);

use dd;
use y;;;;   # requires     export PERL5LIB

open my $OUT, ">&:encoding(UTF-8)", STDOUT;



my @exclude = qw(script style);

my %self_closing = map { $_ => 1 }
    qw(area base br col embed hr img input link meta
    param sourcetrack wbr command keygen menuitem);

our @stack;

# sub new {
#     my $class = shift;
#     my $self = HTML::Parser->new();
# 
#     $self->{all} = 0;
# 
#     while (@_) {
#         my $key = shift;
#         my $value = shift;
#         $self->{ $key } = $value;
#     }
# 
#     return $self;
# }

sub start {
	my ($self, $tagname, $attr, $attrseq, $text) = @_;

    push @stack, $tagname if (not exists $self_closing{ $tagname });
}

sub end {
    my ($self, $tagname, $text) = @_;

    pop @stack if (not exists $self_closing{ $tagname });
}

sub text {
	my ($self, $text, $is_cdata) = @_;
    my $line;

#     dd $self;
#     exit;

    return unless @stack;

    unless (grep { $stack[-1] eq $_ } @exclude) {

        $text = decode_entities($text =~ s/^\s+//r =~ s/\s+$//r);
        $line = "/" . join("/", @stack) . " --> " . GREEN . $text . RESET;
#         $line = YELLOW . "/" . join("/", @stack) . RESET . " --> " . GREEN . $text . RESET;

        if ($self->{all}) {
            say $OUT $line;
        }
        else {
            say $OUT $line if $text ne "";
        }
    }
}


1;
__END__

