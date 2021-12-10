#!/usr/bin/perl

use strict;
use warnings;

# cd /mnt
# mkdir 20G external_drive1 external_drive2 external_drive3 supplement supplement20G usb_key1 usb_key2 usb_key3

sub dmenu {
# 	local $,="\n";
	my $args = shift;
	pipe DREAD,PWRITE;	# dmenu read, perl write -->  ./script.pl | dmenu	(1st step)
	pipe PREAD,DWRITE;	# perl read, dmenu write -->  dmenu | ./script.pl	(2nd step)
	if (!(my $pid=fork)) {
		# dmenu process
		close PREAD;
		close PWRITE;

		close STDIN;
		open STDIN, "<&", \*DREAD;

		close STDOUT;
		open STDOUT, ">&", \*DWRITE;

# 		exec "dmenu -i -l 30";
# 		exec "dmenu -i -l 30 -fn '-xos4-terminus-medium-r-*-*-10-*'";
		exec "dmenu $args -fn '-xos4-terminus-medium-r-*-*-10-*'";
	} else {
		# perl script process
		close DREAD;
		close DWRITE;
		close STDERR;	# avoid error message when pressing Escape in dmenu and making no selection
		
		print PWRITE @_;
		close PWRITE;

		chomp (my $receive = <PREAD>);
		close PREAD;
		return $receive;
	}
}

my $partition;
my $mountpoint;
my $size;
my @dmenu;
our @partitions = `lsblk -rpo "name,type,size,mountpoint"`;

sub first_available_folder {
	my %folders = map {chomp; "/mnt/$_" => 0 } grep {/external_drive/} `ls /mnt`;
	$folders{$_}++ foreach map { (split)[3]  } grep { /external_drive\d/ } @partitions;
	(sort grep {$folders{$_} == 0} keys %folders)[0]
}



# remove partitions that exists in /etc/stab/, remove swap partition
# foreach (grep {!/sda[1236 ]/} grep {/sda/} @partitions) {	# extend it to show external disks
foreach ( grep { @{[split]} < 4 }				# has no mountpoint / is not mounted
          grep {!/sda[1236]/}					# exclude already mounted partitions + swap partition
          grep {/sd[a-z][0-9]+/} @partitions) {	# exclude /dev/sr0 and first line that contains the column names

	($partition, $size)	= (split)[0,2];
	push @dmenu, "$partition   ($size)\n";
}

$partition = (split /\s+/, dmenu "-i -l 30", @dmenu)[0];
exit unless defined $partition;

if ($partition =~ m/sda4/) {
	$mountpoint = "/mnt/supplement";
	#mkdir $mountpoint;
	system "sudo mount $partition $mountpoint";
	chdir $mountpoint;
	system "thunar 2> /dev/null &";
}
elsif ($partition =~ m/sda5/) {
	$mountpoint = "/mnt/supplement20G";
	#mkdir $mountpoint;
	system "sudo mount $partition $mountpoint";
	chdir $mountpoint;
	system "thunar 2> /dev/null &";
}
else {
# 	$mountpoint = "/mnt/external_drive1";
	$mountpoint = first_available_folder();
# 	mkdir $mountpoint;
	system "sudo mount $partition $mountpoint";
	chdir $mountpoint;
	system "thunar 2> /dev/null &";
}



