#!/usr/bin/perl

use strict;
use warnings;
# binmode STDOUT, ":utf8";
binmode STDOUT, ":encoding(UTF-8)";
# use utf8;		# using this cause the little circle before C after temperature, for celsius degree,
                # to be preceded by some A upper case with a diacritic above

sub battery_plugged { -e "/sys/class/power_supply/BAT0" }
sub battery_in_charge {
# 	`cat /sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0A08:00/device:01/PNP0C0A:00/power_supply/BAT0/status`
# 	eq "Charging\n" ?  1 : 0
	my $state = `cat /sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0A08:00/device:01/PNP0C0A:00/power_supply/BAT0/status`;
	if ($state eq "Charging\n" or $state eq "Full\n") {		# "Full\n" is when battery is at 100%, happens only when charging
		return 1;
	}
	else {
		return 0;
	}
}

sub get_battery_charge {
	my ($now,$full) = map {chomp; $_}
    `cat /sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0A08:00/device:01/PNP0C0A:00/power_supply/BAT0/charge_now`,
    `cat /sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0A08:00/device:01/PNP0C0A:00/power_supply/BAT0/charge_full`;
	# /sys/devices/power_supply/BAT0/charge_full
    if ($full == 0) {
        system qw(notify-send -u critical), $full;
        return "??";
    }

	return int(100*$now/$full);
}

sub get_temperatures {
	local $/ = undef;
# 	my ($Tpack, $Tcore0, $Tcore1) = `sensors` =~ m/Package id 0:\s+(\S+).*?Core 0:\s+(\S+).*?Core 1:\s+(\S+)/s;
# 	return "$Tpack $Tcore0 $Tcore1";
	my ($Tcore0, $Tcore1) = `sensors` =~ m/Package id 0:\s+\S+.*?Core 0:\s+(\S+).*?Core 1:\s+(\S+)/s;
	return "$Tcore0 $Tcore1";
}

sub get_available_disk_space { (split /\s+/, join "", grep {/sda3/} `df -h`)[3] }

sub get_date_hour { `date +'%d/%m/20%y | %H:%M'` =~ s/\n$//r }

my $temperatures = get_temperatures();
my $avail_disk = get_available_disk_space();
my $date_hour = get_date_hour();
my $status;

if (battery_plugged()) {
	my $battery_charge = get_battery_charge();
	if (battery_in_charge()) {
# 		$status = "$temperatures | $avail_disk | $date_hour | \N{U+1F5F2} $battery_charge% ";
		$status = "$temperatures | $avail_disk | $date_hour | 🗲 $battery_charge% ";
	}
	else {
		$status = "$temperatures | $avail_disk | $date_hour | $battery_charge% ";
	}
	if ($battery_charge < 10 && ! battery_in_charge()) {
		system qw(notify-send -u critical), "LOW BATTERY";
		# unless status eq "Charging"
	}
}
else {
	$status = "$temperatures | $avail_disk | $date_hour ";
}

system "xsetroot", "-name", $status;

sleep 5;



