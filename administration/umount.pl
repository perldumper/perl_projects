#!/usr/bin/perl

use strict;
use warnings;

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
my @partitions = `lsblk -rpo "name,type,size,mountpoint"`;
my @dmenu;
my %drives;

# lsblk -rpo "name,type,size,mountpoint"
# /dev/sda3 part 465.7G /home
# /dev/sda1 part 93.1G /

foreach ( grep { @{[split]} >= 4}					# has a mountpoint / is mounted
          grep {!/sda[1236]/}						# exclude already mounted partitions + swap partition
          grep {/sd[a-z][0-9]+/} @partitions) {		# exclude /dev/sr0 and first line that contains the column names

	($partition, $size, $mountpoint) = (split)[0,2,3];
	$drives{ $partition } = $mountpoint;
	push @dmenu, "$partition   ($size)\n";
}

$partition = (split /\s+/, dmenu "-i -l 30", @dmenu)[0];
exit unless defined $partition;		# abort when dmenu exited without making a selection

$mountpoint = $drives{$partition};

system "sudo umount $mountpoint";
if ($? == 0) {	# power-off if disk unmounted
	print "there\n";
	unless ($partition =~ m|/dev/sda|) {
		print "here\n";
		system "sudo udisksctl power-off -b $partition && notify-send -u normal \"EXTERNAL DISK REMOVED SUCCESSFULLY\""
	}
}
else {
	system "notify-send", `sudo umount /dev/sdb1 2>&1` =~ s/\n$//r
# 	system "notify-send", `sudo umount $mountpoint 2>&1` =~ s/\n$//r
}



