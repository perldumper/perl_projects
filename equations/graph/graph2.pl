#!/usr/bin/perl

use strict;
use warnings;
use Tk::GraphViz;
use Tk;


my $graph ='graph PathsOfPin {
#    a [label = "aaa"];
#    b [label = "bbb"];
#    c [label = "ccc"];
#    d [label = "ddd"];
#    e [label = "eee"];
#    f [label = "fff"];
#    a--b;
#    c--d;
#    e--f;
#    b--c;
#    d--e;
    a -> b
    c -> d
    e -> f
    b -> c
    d -> e
}';
my $mw = new MainWindow();
my $gv = $mw->GraphViz ( qw/-width 800 -height 800/ )->pack ( qw/-expand yes -fill both/ );

#$gv->fit(); # This does nothing - down't affect the view
#$gv->zoom( -in => 100 ); # This gives me error
$gv->show ( $graph );
MainLoop;

