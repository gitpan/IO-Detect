package IO::Detect;

use 5.010;
use constant { false => !1, true => !0 };
use strict;
use warnings;
use utf8;

BEGIN {
	$IO::Detect::AUTHORITY = 'cpan:TOBYINK';
	$IO::Detect::VERSION   = '0.001';
}

use Sub::Exporter -setup => {
	exports => [
		qw( is_filehandle is_filename is_fileuri ),
		qw( FileHandle FileName FileUri ),
	],
	groups => {
		default    => [qw( is_filehandle is_filename is_fileuri )],
		smartmatch => [qw( FileHandle FileName FileUri )],
	},
};

use overload qw<>;
use Scalar::Util qw< blessed openhandle reftype >;
use URI::file;

sub _ducktype
{
	my ($object, $methods) = @_;
	return unless blessed $object;
	
	foreach (@{ $methods || [] })
	{
		return unless $object->can($_);
	}
	
	return true;
}

sub is_filehandle (_)
{
	my $fh = shift;
	
	return true if openhandle $fh;
	
	# Logic from IO::Handle::Util
	{
		my $reftype = reftype($fh) // '';
		
		if ($reftype eq 'IO'
		or  $reftype eq 'GLOB' && *{$fh}{IO})
		{
			for ($fh->fileno, fileno($fh))
			{
				return unless defined;
				return unless $_ >= 0;
			}
			
			return true;
		}
	}
	
	return true if blessed $fh && $fh->DOES('IO::Handle');
	return true if blessed $fh && $fh->DOES('FileHandle');
	return true if blessed $fh && $fh->DOES('IO::All');
	
	state $expected_methods = [qw(
		close eof fcntl fileno getc getline getlinesioctl read print stat
	)];
	return _ducktype $fh, $expected_methods; 
}

sub _oneline ($)
{
	my $str = shift;
	my @bits = split /\r?\n|\r/, $str;
	scalar(@bits)==1;
}

sub is_filename (_)
{
	my $f = shift;
	return true if blessed $f && $f->DOES('IO::All');
	return true if blessed $f && $f->DOES('Path::Class::Entity');
	return true if blessed $f && overload::Method($f, q[""]) && length "$f" && _oneline $f;
	return true if defined $f && (!ref $f) && length $f && _oneline $f;
	return;
}

sub is_fileuri (_)
{
	my $f = shift;
	return $f if blessed $f && $f->DOES('URI::file');
	return URI::file->new($f->uri) if blessed $f && $f->DOES('RDF::Trine::Node::Resource');
	return URI::file->new($f) if $f =~ m{^file://\S+}i;
	return;
}

{
	package IO::Detect::SmartMatcher;
	use Scalar::Util qw< blessed >;
	use overload
		'""'     => 'to_string',
		'~~'     => 'check',
		fallback => 1;
	sub check
	{
		my ($self, $thing) = @_;
		$self->[1]->($thing);
	}
	sub to_string
	{
		shift->[0]
	}
	sub new
	{
		my $proto = shift;
		if (blessed $proto and $proto->isa(__PACKAGE__))
		{
			return "$proto"->new(@_);
		}
		bless \@_ => $proto;
	}
}

sub FileHandle ()
{
	state $t = IO::Detect::SmartMatcher::->new(
		FileHandle => \&is_filehandle,
	);
	$t;
}

sub FileName ()
{
	state $t = IO::Detect::SmartMatcher::->new(
		FileName => \&is_filename,
	);
	$t;
}

sub FileUri ()
{
	state $t = IO::Detect::SmartMatcher::->new(
		FileUri => \&is_fileuri,
	);
	$t;
}

true;

__END__

=encoding utf8

=head1 NAME

IO::Detect - is this a frickin' filehandle or what?!

=head1 SYNOPSIS

	use IO::Detect;
	
	if (is_filehandle $fh)
	{
		my $line = <$fh>;
	}

=head1 DESCRIPTION

It is stupidly complicated to detect whether a given scalar is
a filehandle (or something filehandle like) in Perl. This module
attempts to do so, but probably falls short in some cases. The
primary advantage of using this module is that it gives you
somebody to blame (me) if your code can't detect a filehandle.

The main use case for IO::Detect is for when you are writing
functions and you want to allow the caller to pass a file as
an argument without being fussy as to whether they pass a file
name or a file handle.

=head2 Functions

Each function takes a single argument, or if called with no
argument, operates on C<< $_ >>.

=over

=item C<< is_filehandle $thing >>

Theoretically returns true if and only if $thing is a file handle,
or may be treated as a filehandle. That includes blessed references
to filehandles, things that inherit from IO::Handle, etc.

It's never going to work 100%. What Perl allows you to use as a
filehandle is mysterious and somewhat context-dependent, as the
following code illustrates.

	my $fh = "STD" . "OUT";
	print $fh "Hello World!\n";

=item C<< is_filename $thing >>

Returns true if $thing is a L<IO::All> object or L<Path::Class::Entity>
or L<any non-reference, non-zero-length string with no line breaks>.
That's because depending on your operating system, virtually anything
can be used as a filename. (In fact, on many systems, including Linux,
filenames can contain line breaks. However, this is unlikely to be
intentional.)

This function doesn't tell you whether $thing is an existing file on
your system. It attempts to tell you whether $thing could possibly be
a filename on some system somewhere.

=item C<< is_fileuri $thing >>

Returns true if $thing is a URI beginning with "file://". It
allows for L<URI> objects, L<RDF::Trine::Node::Resource> objects,
strings and objects that overload stringification.

This function actually returns an "interesting value of true". The
value returned is a L<URI::file> object.

=back

=head2 Smart Matching

You can import three constants for use in smart matching:

	use IO::Detect -smartmatch;

These constants are:

=over

=item C<< FileHandle >>

=item C<< FileName >>

=item C<< FileUri >>

=back

They can be used like this:

	if ($file ~~ FileHandle)
	{
		...
	}

Note that there does exist a L<FileHandle> package in Perl core. This
module attempts to do the right thing so that C<< FileHandle->new >>
still works, but there are conveivably places this could go wrong, or
be plain old confusing.

=head2 Precedence

Because there is some overlap/ambiguity between what is a filehandle
and what is a filename, etc, if you need to detect between them, I
recommend checking C<is_filehandle> first, then C<is_fileuri> and
falling back to C<is_filename>.

	for ($file)
	{
		when (FileHandle)  { ... }
		when (FileUri)     { ... }
		when (FileName)    { ... }
		default            { die "$file is not a file!" }
	}

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=IO-Detect>.

=head1 SEE ALSO

This module is an attempt to capture some of the wisdom from this
PerlMonks thread L<http://www.perlmonks.org/?node_id=980665> into
executable code.

Various other modules that may be of interest, in no particular
order...
L<Scalar::Util>,
L<FileHandle>,
L<IO::Handle>,
L<IO::Handle::Util>,
L<IO::All>,
L<Path::Class>,
L<URI::file>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

