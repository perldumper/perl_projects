#!/usr/bin/perl -l

# use case
# classify by filetype files from the Downloads/ directory when too much garbage in it

use strict;
use warnings;

my %hash= (
word         => ['doc', 'docx', 'odt'],
excel        => ['xls', 'xlsx', 'ods'],
documents    => ['pdf', 'ps', 'epub','djvu'],
presentation => ['ppt', 'pptx', 'pps', 'odp'],
txt          => ['txt','md'],
pictures     => ['jpg', 'jpeg', 'png', 'tif', 'swf', 'bmp', 'gif', 'svg'],
audio        => ['mp3', 'wav', 'wma','opus', 'm4a'],
video        => ['srt', 'vtt', 'wmv', 'avi', 'mp4', 'mkv', 'webm', 'ts', 'mpg', 'mpeg', 'mov'],
# web_pages    => ['htm', 'html', 'xml', 'css', 'js'],
web_pages    => ['htm', 'html', 'xml', 'css'],
archives     => ['rar', 'zip', 'tar\.gz', 'tar\.bz2', 'tar\.lz', 'tar', 'tgz', 'tar\.lz\.sig', '7z', 'deb'],
exe          => ['exe', 'dll', 'sys'],
scripts      => [ 'sh','pl','pm', 'pl6', 'php', 'c', 'o', 'js', 'py', 'pyc'],
links        => [ 'torrent', 'm3u', 'm3u8'],
autocad      => [ 'dwg', 'dwt', 'dst', 'dgn'],
data         => ['db', 'csv']
);

my %files;

foreach my $category (keys %hash){
	foreach my $extension ($hash{$category}->@*) {
		push $files{$category}->@*, grep {/\.$extension$/i} `ls`;
	}
}

# there are 2 invocations possible: ./script.pl and perl script.pl
$0 =~ s|^\./||;

# remove this current script file from the list of files to move
chomp $files{scripts}->@*;
$files{scripts}->@* = grep { $_ ne $0 } $files{scripts}->@*;

foreach my $category (keys %hash) {
	print "\nCATEGORY $category" unless $files{$category}->@* == 0;
	mkdir ($category) unless $files{$category}->@* == 0; #uncomment this line

	foreach my $files_to_move ($files{$category}->@*) {
		chomp $files_to_move;
		print $files_to_move;
		system("mv","-v","$files_to_move","$category/");  #uncomment this line
	}
}	
