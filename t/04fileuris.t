use Test::More;
use IO::Detect qw( is_fileuri FileUri );
use URI;

{
	package Local::Stringifier;
	use overload q[""], sub { $_[0][0] };
	sub new { bless \@_, shift }
}

my @uris = qw(
	file://localhost/etc/fstab
	file:///etc/fstab
	file:///c:/WINDOWS/clock.avi
	file://localhost/c|/WINDOWS/clock.avi
	file:///c|/WINDOWS/clock.avi
	file://localhost/c:/WINDOWS/clock.avi
	file://localhost///remotehost/share/dir/file.txt
	file://///remotehost/share/dir/file.txt 
);

@uris = (
	@uris,
	(map { Local::Stringifier->new($_) } @uris),
	(map { URI->new($_) } @uris),
);

if ($] >= 5.010)
{
	eval q[
		ok(is_fileuri, sprintf("is_fileuri %s %s", ref $_, $_)) foreach @uris;
		ok($_ ~~ FileUri, sprintf("is_fileuri %s %s", ref $_, $_)) foreach @uris;
	];
}

ok not is_fileuri 'http://localhost/';

ok not is_fileuri "http://localhost/\nfile://";

done_testing();
