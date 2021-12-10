
package download;

use strict;
use warnings;
use v5.10;
use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;
use Carp;
use Term::ANSIColor qw(:constants);
use File::Stat;
use String::Formatter;


our $formatter;
local $formatter;

# FILENAME ==> remove  ?option=value
# "perly-parsing-with-regexpgrammars-27-1024.jpg?cb=1426881287"


sub next_available_filename {
    my $format = shift // carp("no format specified");
    $formatter //= String::Formatter->new({
            codes => {
                d => sub { $_[1] }
            }
    });

    my $i=1;
    my $filename;

    do {
        $filename = $formatter->format($format, $i++)

    } while (-e $filename);
    
    return $filename;
}

# LWP::UserAgent
# 
#    request
#            my $res = $ua->request( $request );
#            my $res = $ua->request( $request, $content_file );
#            my $res = $ua->request( $request, $content_cb );
#            my $res = $ua->request( $request, $content_cb, $read_size_hint );


sub download_url {
    my $ua = shift;
    carp("not a method") if UNIVERSAL::isa($ua, "download");;
    my $file;

    while (@_) {
        my $url = shift;

        unless ($file = shift) {
            $file = $url =~ s|^.*/([^/]+)$|$1|r;                # "basename" of url
            if ($file !~ m|/$|) {
                $file !~ m/^.*\.[^.]+$/ and $file .= ".html";   # add .html if no extension
                $file = uri_unescape($file);                    # %20 --> " ", URI percent encoding
            }
            else {
                $file = next_available_name("downloaded_webpage");
        #         $file !~ m/^.*\.[^.]+$/ and $file .= ".html";   # add .html if no extension
                # improve next_available_name
            }
        }

        my $response = $ua->get($url, ":content_file" => $file);

        if ($response->is_success) {
            print STDERR GREEN, "\"$file\"", RESET, "\n";
        }
        else {
            die "download error";
        }
    }
}



sub new {
    my $class = shift;
    my %self = (    # default
        progress    => 1,
        overwrite   => 0,
        log         => 0,
    );
    while (@_) {
        my $key = shift;
        my $value = shift;
        $self{ $key } = $value;
    }

	$self{ua} = LWP::UserAgent->new();
    $self{ua}->show_progress( $self{progress} );
    $self{ua}->agent("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36");


    bless \%self, $class;
}

sub file {
    my $self = shift;
    my %args = @_;
    my $filename;
    my $response;
    my $size;

    if (! defined $args{url}) {
        croak("url not defined");
    }

    if (exists $args{filename} && $args{filename} ne "") {
        $filename = $args{filename};
    }
    else {
        ($filename) = $args{url} =~ m| ^ .* / ([^/]+) $ |x;

        $filename = uri_unescape($filename);
    }

    if (-e $filename) {

#         $self->{ua}->show_progress(0);

        $response = $self->{ua}->head($args{url});
        $size = $response->{_headers}{"content-length"};

        if ($self->{progress}) {
            print STDERR "\e[A";
            print STDERR " " x 200;
            print STDERR "\r";
            print STDERR "\e[A";
        }

#         $self->{ua}->show_progress( $self->{progress} );

        # ALSO TEST OTHER FILENAMES
        if ($size == File::Stat->new($filename)->size) {
#             say STDERR "file with same filename and same size already exists";
            if ($self->{log}) {
                say STDERR "\"$filename\"";
            }
        }
        elsif ($self->{overwrite}) {
            $response = $self->{ua}->get( $args{url}, ":content_file" => $filename);

            if ($response->is_success) {
                if ($self->{progress}) {
#                     print STDERR "\e[2A";
                    print STDERR "\e[A";
                    print STDERR " " x 200;
                    print STDERR "\r";
                    print STDERR "\e[A";
                }
                say STDERR GREEN, "\"$filename\"", RESET if $self->{log};
            }
            else {
#                 carp(RED . "ERROR while downloading $args{url}" . RESET);
                say STDERR RED, $args{url}, RESET;
            }
        }
        else {
            carp("filename $filename contains '%d'") if $filename =~ /%d/;

            my ($name, $ext) = $filename =~ m/ ^ (.*) (\. [^.]+) $ /x;

            $filename = next_available_filename($name . ".%d" . $ext);

            $response = $self->{ua}->get( $args{url}, ":content_file" => $filename);

            if ($response->is_success) {
                if ($self->{progress}) {
#                     print STDERR "\e[2A";
                    print STDERR "\e[A";
                    print STDERR " " x 200;
                    print STDERR "\r";
                    print STDERR "\e[A";
                }
                say STDERR GREEN, "\"$filename\"", RESET if $self->{log};
            }
            else {
#                 carp(RED . "ERROR while downloading $args{url}" . RESET);
                say STDERR RED, $args{url}, RESET;
            }
        }
    }
    else {
        $response = $self->{ua}->get( $args{url}, ":content_file" => $filename);

        if ($response->is_success) {
            if ($self->{progress}) {
#                 print STDERR "\e[2A";
                print STDERR "\e[A";
                print STDERR " " x 200;
                print STDERR "\r";
                print STDERR "\e[A";
            }
           say STDERR GREEN, "\"$filename\"", RESET if $self->{log};
        }
        else {
#             carp(RED . "ERROR while downloading $args{url}" . RESET);
            say STDERR RED, $args{url}, RESET;
        }
    }

}

1;

__END__


$download->new(
    ERROR HANDLING
    return error ?  --> die, try/catch
);

