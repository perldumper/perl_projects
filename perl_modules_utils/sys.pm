
# use File::Basename;		# basename dirname fileparse
# use File::Copy;			# copy move
use Capture::Tiny ":all";	# capture
# use File::Path qw(remove_tree);
# use File::Find;

sub copy {
	require File::Copy;
	my ($source, $destination) = @_;
# 	eval "File::Copy::copy \"$source\", \"$destination\" ";
	eval "File::Copy::copy \$source, \$destination";
}

sub move {
	require File::Copy;
	my ($source, $destination) = @_;
# 	eval "File::Copy::move \"$source\", \"$destination\" ";
	eval "File::Copy::move \$source, \$destination";
}

sub basename {
	require File::Basename;
	my ($fullname, @suffixlist) = @_;
	eval "File::Basename::basename \$fullname, \@suffixlist";
}

sub dirname {
	require File::Basename;
	my $fullname = shift;
	eval "File::Basename::dirname \$fullname";
}

sub fileparse {
	require File::Basename;
	my ($fullname, @suffixlist) = @_;
	eval "File::Basename::fileparse \$fullname, \@suffixlist";
}

sub remove_tree {
	require File::Path;
	my @dirs = @_;
	eval "File::Path::remove_tree \@dirs";
# 	eval "File::Path::remove_tree \@_";
}

# sub capture {
# sub capture(&;@) {
# 	require Capture::Tiny;
# 	require Capture::Tiny ':all';
# 	eval "require Capture::Tiny";
# 	eval "require Capture::Tiny ':all'";
# 	eval "use Capture::Tiny";
# 	eval "use Capture::Tiny ':all'";
# 	my $code = shift;
# 	eval "&Capture::Tiny::capture \$code";
# 	eval "&{Capture::Tiny::capture} \$code";
# 	eval "&{'Capture::Tiny::capture'} \$code";
# 	eval "Capture::Tiny::capture \$code";
# 	eval "Capture::Tiny::capture \@_";
# }

# builtins
# link	# ln -s ???
# symlink	# ln -s ???

# open	# touch
# mkdir

# rename
# -X
# glob

# chdir	# cd
# chmod
# chown
# umask

# unlink	# rm
# rmdir

sub slurp {
	my $path = shift;
	local $/ = undef;
	local $\ = "";
	open my $FH, "<", $path or die "Can't open file \"$path\"\n";
# 	open my $FH, "<:encoding(UTF-8)", $path or die "Can't open file \"$path\"\n";
	my $file = <$FH>;
	close $FH;
	return $file;
}

sub spurt {
	my $path = shift;
	local $\ = "\n";
	open my $FH, ">", $path or die "Can't open file \"$path\"\n";
	print $FH @_;
	close $FH;
}

sub find {
	if (@_) {
		map { chomp; $_ } map { $_=quotemeta; `find $_` } @_
	}
	else {
		map { chomp; $_ } `find`
	}
}

1;



__END__

File::Copy


NOTES
Before calling copy() or move() on a filehandle, the caller
should close or flush() the file to avoid writes being lost. Note
that this is the case even for move(), because it may actually
copy the file, depending on the OS-specific implementation, and
the underlying filesystem(s).

