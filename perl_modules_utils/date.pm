
package date;
use strict;
use warnings;

sub new {
	my $class = shift;
	bless {}, $class;
}

sub today {
	my $self = shift;
	my ($day, $month, $year, $weekday);
	((undef)x3, $day, $month, $year, $weekday) = localtime;
	$month++;
	$self->{year} = 1900 + $year;
	$self->{month} = $month;
	$self->{day} = $day;
	$self->{weekday} = $weekday;
	return $self;
}

sub next_day {
	my $self = shift;
	my @month_is_30 = (4,6,9,11);
	my @month_is_31 = (1,3,5,7,8,10,12);

	$self->{weekday} = $self->{weekday} < 6 ? $self->{weekday} + 1 : 0;
	
	if (grep { $_ == $self->{month} } @month_is_31) {
		if ($self->{day} < 31) {
			$self->{day}++;
		}
		elsif ($self->{day} == 31) {
			$self->{day} = 1;
			if ($self->{month} < 12) {
				$self->{month}++;
			}
			elsif ($self->{month} == 12) {
				$self->{month} = 1;
				$self->{year}++;
			}
		}
	}
	elsif (grep { $_ == $self->{month} } @month_is_30) {
		if ($self->{day} < 30) {
			$self->{day}++;
		}
		elsif ($self->{day} == 30) {
			$self->{day} = 1;
			if ($self->{month} < 12) {
				$self->{month}++;
			}
			elsif ($self->{month} == 12) {
				$self->{month} = 1;
				$self->{year}++;
			}
		}
	}
	elsif ($self->{month} == 2) {	# February
		if ($self->{year} % 4 == 0) {
			if ($self->{day} < 29) {
				$self->{day}++;
			}
			elsif ($self->{day} == 29) {
				$self->{day} = 1;
				$self->{month} = 3;
			}
		}
		elsif ($self->{year} % 4 != 0) {
			if ($self->{day} < 28) {
				$self->{day}++;
			}
			elsif ($self->{day} == 28) {
				$self->{day} = 1;
				$self->{month} = 3;
			}
		}
	}
	return $self;
}

sub previous_day {
	my $self = shift;
	my @month_before_is_30 = (5,7,10,12);
	my @month_before_is_31 = (1,2,4,6,8,9,11);

	$self->{weekday} = $self->{weekday} > 0 ? $self->{weekday} - 1 : 6;

	if (grep { $_ == $self->{month} } @month_before_is_31) {
		if ($self->{day} > 1) {
			$self->{day}--;
		}
		elsif ($self->{day} == 1) {
			$self->{day} = 31;
			if ($self->{month} > 1) {
				$self->{month}--;
			}
			elsif ($self->{month} == 1) {
				$self->{month} = 12;
				$self->{year}--;
			}
		}
	}
	elsif (grep { $_ == $self->{month} } @month_before_is_30) {
		if ($self->{day} > 1) {
			$self->{day}--;
		}
		elsif ($self->{day} == 1) {
			$self->{day} = 30;
			if ($self->{month} > 1) {
				$self->{month}--;
			}
			elsif ($self->{month} == 1) {
				$self->{month} = 12;
				$self->{year}--;
			}
		}
	}
	elsif ($self->{month} == 3) {	# March
		if ($self->{year} % 4 == 0) {
			if ($self->{day} > 1) {
				$self->{day}--;
			}
			elsif ($self->{day} == 1) {
				$self->{day} = 29;
				$self->{month} = 2;
			}
		}
		elsif ($self->{year} % 4 != 0) {
			if ($self->{day} > 1) {
				$self->{day}--;
			}
			elsif ($self->{day} == 1) {
				$self->{day} = 28;
				$self->{month} = 2;
			}
		}
	}
	return $self;
}

sub string {
	my $self = shift;
	my @days = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
	my ($day, $month) = ($self->{day}, $self->{month});
	$day =~ m/^\d$/ and $day =~ s/^/0/;
	$month =~ m/^\d$/ and $month =~ s/^/0/;
	return sprintf "%-10s%s-%s-%s", $days[$self->{weekday}], $self->{year}, $month, $day;
}

sub format {
	my $self = shift;
	my ($day, $month) = ($self->{day}, $self->{month});
	$day =~ m/^\d$/ and $day =~ s/^/0/;
	$month =~ m/^\d$/ and $month =~ s/^/0/;
	return "$self->{year}-$month-$day";
}



1;
__END__

