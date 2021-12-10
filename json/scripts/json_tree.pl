#!/usr/bin/perl

use strict;
use warnings;

# based on the stream of tokens, make the json into a hash

my %root;
my %curly_open;
my %square_open;
my %key;
my %colon;
my %terminal;
my %comma;
my %curly_close;
my %square_close;
my %end;


%root = (curly_open => \%curly_open,
        square_open => \%square_open);

%curly_open = (string => \%key );

%square_open = (number => \%terminal,
                string => \%terminal,
                  true => \%terminal,
                 false => \%terminal,
                  null => \%terminal,
            curly_open => \%curly_open,
           square_open => \%square_open);

%key = (colon => \%colon);

%colon = (number => \%terminal,
          string => \%terminal,
            true => \%terminal,
           false => \%terminal,
            null => \%terminal,
      curly_open => \%curly_open,
     square_open => \%square_open );

%terminal = (comma => \%comma,
       curly_close => \%curly_close,
      square_close => \%square_close);

%comma = (number => \%terminal,
          string => \%terminal,
            true => \%terminal,
           false => \%terminal,
            null => \%terminal,
          string => \%key); # CONFLICT

%curly_close = (curly_close => \%curly_close,
               square_close => \%square_close,
                      comma => \%comma,
                        end => \%end);

%square_close = (curly_close => \%curly_close,
                square_close => \%square_close,
                       comma => \%comma,
                         end => \%end);

%end = ();



