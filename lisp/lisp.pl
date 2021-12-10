#!/usr/bin/perl

# falsity ?
#
# NIL
# 4
# 'a
# "text"
# dotted pairs
# (1 . 2)
# (1 2 3 . 4)
# (2)
# (1 2 3)
# (1 2)
# ((1 2) (3 4) (5 (6 7) 8))
# (1 2 3 (4 5) 6 (7) ((8 9) (10) 11))


# if next element is atom --> "$cur "
# if next element is list "(" . string(cdr(x))
# if next element is null --> "$cur)"
# if cdr is atom and cdr is not null "$car . $cdr)"
#
#
#

# $ lisp -e "(say (caar '('(1 a) 2 3)))"
# QUOTE


# TO DO
# 1) find a simple grammar for S-expression  + syntactic sugar '(1 2 3) => (quote (1 2 3))
#
# 2) make a recursive descent parser which uses cons / car / cdr below to build the parse tree
#
# 3) translate the lisp eval function in perl,
# using car/cdr/_eq/atom/quote/null/cons   below
# (do not make a cond function in perl, use perl's native conditionals if/elsif/else instead)
#
# 4) run eval with argument the S-expression parsed with the recursive descent parser

# modify the implementation of cons ? --> if so, change car/cdr/null/atom etc.


use strict;
use warnings;
no warnings 'experimental::regex_sets';
use y;;;;
use dd;

local $,="";
# local $,=" ";
local $\="\n";

sub car {
    ref $_[0] eq "ARRAY"
    ? $_[0]->[0]
#     : "NIL"
    : []
    # else die "CAR argument \"$_[0]\" not a CONS"
}

sub cdr {
    ref $_[0] eq "ARRAY"
    ? $_[0]->[1]
#     : "NIL"
    : []
}

sub caar { car(car($_[0])) }
sub cadr { car(cdr($_[0])) }
sub cdar { cdr(car($_[0])) }
sub cddr { cdr(cdr($_[0])) }
sub caaar { car(car(car($_[0]))) }
sub caadr { car(car(cdr($_[0]))) }
sub cadar { car(cdr(car($_[0]))) }
sub caddr { car(cdr(cdr($_[0]))) }
sub cdaar { cdr(car(car($_[0]))) }
sub cdadr { cdr(car(cdr($_[0]))) }
sub cddar { cdr(cdr(car($_[0]))) }
sub cdddr { cdr(cdr(cdr($_[0]))) }
sub caaaar { car(car(car(car($_[0])))) }
sub caaadr { car(car(car(cdr($_[0])))) }
sub caadar { car(car(cdr(car($_[0])))) }
sub caaddr { car(car(cdr(cdr($_[0])))) }
sub cadaar { car(cdr(car(car($_[0])))) }
sub cadadr { car(cdr(car(cdr($_[0])))) }
sub caddar { car(cdr(cdr(car($_[0])))) }
sub cadddr { car(cdr(cdr(cdr($_[0])))) }
sub cdaaar { cdr(car(car(car($_[0])))) }
sub cdaadr { cdr(car(car(cdr($_[0])))) }
sub cdadar { cdr(car(cdr(car($_[0])))) }
sub cdaddr { cdr(car(cdr(cdr($_[0])))) }
sub cddaar { cdr(cdr(car(car($_[0])))) }
sub cddadr { cdr(cdr(car(cdr($_[0])))) }
sub cdddar { cdr(cdr(cdr(car($_[0])))) }
sub cddddr { cdr(cdr(cdr(cdr($_[0])))) }

sub cons { [$_[0], $_[1]] }

# sub cond { }

sub quote { $_[0] }

sub _eq {
    if (ref $_[0] eq "" and ref $_[1] eq "") {
        $_[0] eq $_[1] ? 1 : 0
    }
    elsif (null($_[0]) and null($_[1])) {
        1
    }
    else {
        0
    }
}

sub atom {
    if (ref $_[0] eq "") { 1 }
    elsif (null($_[0]))  { 1 }
}

sub null {
    if (ref $_[0] eq "ARRAY") {
        $_[0]->@* == 0 ? 1 : 0
    }
    else {
        0
    }
}

sub is_quote {
    _eq(car($_[0]), "QUOTE")
#     _eq(car($_[0]), "quote")
}

sub stringify_dsc {
    if (atom($_[0])) {
        stringify_atom($_[0])
    } 
    else {
        join "", stringify_list($_[0])
    }
}

sub stringify_list {
    if (atom(car($_[0]))) {
        if (is_quote($_[0])) {
            join "", "'", stringify_list(cadr($_[0]))
        }
        else {
            join "", "(", stringify_list_first(car($_[0])), stringify_list_rest(cdr($_[0]))
        }
    }
    else {
        join "", "(", stringify_list(car($_[0])), stringify_list_rest(cdr($_[0]))
    }
}

#  a list is separated into its first element and the rest of elements to deal with spaces
#  every element of a list, except the first is preceded by a space
#  ex: '(a b c)

sub stringify_list_first {
    if(null($_[0])) {           # empty list
        ""
    }
    elsif (atom($_[0])) {       # first element is an atom
        stringify_atom($_[0])
    }
    else {                      # first element is a cons/list
        join "", stringify_list($_[0])
    }
}

sub stringify_list_rest {
    if (null($_[0])) { # end of the list
        ")"
    }
    # dotted pair
    elsif (atom($_[0])) {
        join "", " . ", stringify_atom($_[0]), ")"
    }
    # current element is an atom
    elsif (atom(car($_[0]))) {
        join "", " ", stringify_atom(car($_[0])), stringify_list_rest(cdr($_[0]))
    }
    # current element is a cons/list
    else {
        join "", " ", stringify_list(car($_[0])), stringify_list_rest(cdr($_[0]))
    }
}

sub stringify_atom { # convert various types to string
    if (null($_[0])) {
        "NIL"
     }
     else {
#         (string l)
#         $_[0]
        uc $_[0]
     }
}

sub princ {
    if (ref $_[0] eq "ARRAY") {
        print stringify_dsc($_[0]);
    }
#     else { print $_[0] }
    else { print uc $_[0] }
}

############
#   TEST   #
############

# print car( cons("a", "z") );
# print cdr( cons("a", "z") );
# print car( cdr( cons("a", "z") ));
# print cdr( cdr( cons("a", "z") ));
# 
# print cons("a", "z");
# dd cons("a", "z");


# print cons(1, cons (2, 3))->@*;
# princ(cons(1, cons (2, cons(3, []))));
# princ(cons("QUOTE", cons(1, cons (2, cons(3, [])))));
# lisp -e '(say (cons "quote" (cons 1 (cons 2 (cons 3 nil)))))'


# atoms
# (test-print ())
# (test-print 'a)
#  
# princ([]);
# princ("a");
# 
# lists
# (test-print '(a))
# (test-print '(a b c))
# princ(cons("a", []));
# princ(cons("a", cons("b", cons("c", []))));
# 
# lists of lists
# (test-print '(a b c (d e f)))
# (test-print '((a (b)) c (d e f)))
# (test-print '((a (b)) c ((d ((e))) f)))
#  
# princ(cons("a", cons("b", cons("c", cons(cons("d", cons("e", cons("f", []))), [])))));
# princ(cons(cons("a", cons(cons("b", []), [])), cons("c", cons(cons("d", cons("e", cons("f", []))), []))));
# 
# princ(cons(cons("a", cons(cons("b", []), [])), cons("c",
#  cons(cons(cons("d", cons(cons(cons("e", []), []), [])), cons("f", [])), []))
# ));
#
# nil in a list
# (test-print '(a () c))
# (test-print '(a nil c))
#  
# princ(cons("a", cons([], cons("c", []))));
# 
# dotted pairs
# (test-print '(a . b))
# (test-print '((a . b)))
# (test-print '(a b . c))
# (test-print '(a (b . c)))
#  
# princ(cons("a", "b"));
# princ(cons(cons("a", "b"), []));
# princ(cons("a", cons("b", "c")));
# princ(cons("a", cons(cons("b", "c"), [])));
# 
# quote
# (test-print '(a b c '(d e f)))
# (test-print '(a '(b) c '(d '(e) f)))
# 
# princ(cons("quote", cons(cons("d", cons("e", cons("f", []))), [])));
# princ(cons("QUOTE", cons(cons("d", cons("e", cons("f", []))), [])));
# 
# princ(cons("a", cons("b", cons("c", cons(cons("QUOTE", cons(cons("d", cons("e", cons("f", []))), [])), [])))));
# 
# (test-print '(a '(b) c (quote (d '(e) f))))
# (test-print '(a '(b) c '(quote (d '(e) f))))
#  
# (test-print '(a '(b) c (quote '(d '(e) f))))
# (test-print '(a '(b) c '(quote '(d '(e) f))))






__END__
exit;

top -> [ quoted expression | expression ] *

quoted expression -> "'" expression

expression -> atom | list

list -> '(' ws? expression * %% ws ')'

atom -> number | bareword | doublequoted word

list
parens
single quote
atom -> number, bareword, doublequoted word


my $sexp = '(princ (car (cdr (cons 1 (cons 2 3)))) )(terpri)';
my @tokens;

my $end=0;
while (not $end) {
	if ($sexp =~ m/\G \s+ /gcx) {
# 		print "WS"
	}
	elsif ($sexp =~ m/\G \( /gcx) {
# 		print "PAREN";
		print "(";
		push @tokens, { type => "lparen", value => '(' };
	}
	elsif ($sexp =~ m/\G \) /gcx) {
# 		print "PAREN";
		print ")";
		push @tokens, { type => "rparen", value => ')' };
	}
	elsif ($sexp =~ m/\G ( (?[ [\S] - [()] ])+ ) /gcx) {
# 		print "WORD";
		print $1;
		push @tokens, { type => "word", value => $1 };
	}
	else {
# 		print "END";
		$end = 1;
	}
}


__END__


# cXr
# perl -Mset -le 'for $n (2..4) { for (set_product(eval(join ",", ("[qw(a d)]") x $n))) { $body="c$_->[-1]r(\$_[0])"; for($i = $_->$#*-1; $i >= 0; $i--){ $body="c$_->[$i]r($body)" } print join "", "sub c", $_->@*, "r { $body }"  } }' 

# sub set_product {		# cartesian product of n sets
# 	my @array_of_aref = @_;
# 	if (@array_of_aref == 0) {
# 		return;
# 	}
# 	elsif (@array_of_aref == 1) {
# 		return $array_of_aref[0];
# 	}
# 	elsif (@array_of_aref >= 2) {
# 		my $array_a = shift @array_of_aref;
# 		my $array_b = shift @array_of_aref;
# 		my @array_c;
# 		foreach my $a ($array_a->@*) {
# 			foreach my $b ($array_b->@*) {
# 				if (ref $a eq "" and ref $b eq "") {
# 					push @array_c, [$a,     $b];
# 				}
# 				elsif (ref $a eq "ARRAY" and ref $b eq "") {
# 					push @array_c, [$a->@*, $b];
# 				}
# 				elsif (ref $a eq "" and ref $b eq "ARRAY") {
# 					push @array_c, [$a,     $b->@*];
# 				}
# 				elsif (ref $a eq "ARRAY" and ref $b eq "ARRAY") {
# 					push @array_c, [$a->@*, $b->@*];
# 				}
# 			}
# 		}
# 		while ( defined (my $aref = shift @array_of_aref)) {
# 			@array_c = set_product(\@array_c, $aref);
# 		}
# 		return @array_c;
# 	}
# }









