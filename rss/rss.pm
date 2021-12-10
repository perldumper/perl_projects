
package rss;

use strict;
use warnings;
use Carp;
use XML::LibXML;
use LWP::UserAgent;
use utf8;


sub remove_accents {
    $_[0]
    =~ tr/àÀâÂäÄçÇéÉèÈêÊëËîÎïÏôÔöÖùÙûÛüÜÿŸ/aAaAaAcCeEeEeEeEiIiIoOoOuUuUuUyY/r
    =~ tr/’/'/r
}

sub new {
    my $class = shift;
    my %args = @_; # file/string/url, group_by => date/author
    my $rss_files;
    my $rss_xml_dom;

    if (exists $args{file}) {
        if ( ! defined $args{file}) {
            croak "file given is undefined";
        }
        elsif ( ! -e $args{file}) {
            croak "\"$args{file}\" does not exists";
        }
        $rss_xml_dom = XML::LibXML->load_xml(location => $args{file});
    }
    elsif (exists $args{string}) {
        if ( ! defined $args{string}) {
            croak "string given is undefined";
        }
        $rss_xml_dom = XML::LibXML->load_xml(string => $args{string});
    }
    elsif (exists $args{url}) {
        my $ua = LWP::UserAgent->new;
        $ua->agent("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36");

        my $request = HTTP::Request->new(GET => $args{url});
        my $response = $ua->request($request);
        if (! $response->is_success) { # not tested
            croak "error while downloading \"$args{url}\""
        }
        $rss_xml_dom = XML::LibXML->load_xml(string => $response->{_content});
    }
    else {
        croak "no input specified";
    }

    $rss_files = _get_rss_files($rss_xml_dom, \%args);
    
    return bless $rss_files, $class;
}

sub _get_rss_files {
    my ($rss_xml_dom, $args) = @_;
    my $rss_files;
    my ($title, $date);

    if (not exists $args->{group_by}) {

        foreach my $node ($rss_xml_dom->findnodes("/rss/channel/item")) {

            $title = $node->findvalue("./title");
#             next if $title eq "Retrouvez tous les épisodes sur l’appli Radio France";

            ($date) = $node->findvalue("./pubDate") =~ s/^\w\w\w, \d\d \w\w\w \d\d\d\d\K.*//r;

            push $rss_files->@*, {
        # 		title        => $title,
                title        => remove_accents($title), # CURRENT
        # 		title        => revove_accents($title) =~ tr/\t//rd,
                link         => $node->findvalue('./link'),
                description  => $node->findvalue('./description'),
                url          => $node->findvalue('./enclosure/@url'),
                author       => $node->findvalue('./itunes:author'),
                duration     => $node->findvalue('./itunes:duration'),
                date         => $date,
            };
        }

    }
    elsif ($args->{group_by} eq "date" || $args->{group_by} eq "author") {

        my $group_by = $args->{group_by};

        foreach my $node ($rss_xml_dom->findnodes("/rss/channel/item")) {

            $title = $node->findvalue("./title");
#             next if $title eq "Retrouvez tous les épisodes sur l’appli Radio France";

            ($date) = $node->findvalue("./pubDate") =~ s/^\w\w\w, \d\d \w\w\w \d\d\d\d\K.*//r;

            push $rss_files->{ $group_by }->@*, {
        # 		title        => $title,
                title        => remove_accents($title), # CURRENT
        # 		title        => revove_accents$title) =~ tr/\t//rd,
                link         => $node->findvalue('./link'),
                description  => $node->findvalue('./description'),
                url          => $node->findvalue('./enclosure/@url'),
                author       => $node->findvalue('./itunes:author'),
                duration     => $node->findvalue('./itunes:duration'),
                date         => $date,
            };
        }
    }
    return $rss_files;
}


1;
__END__






