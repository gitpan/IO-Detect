use Test::More;
use IO::Detect qw( is_filename FileName );

my @filenames = qw(
	0
	/dev/null
	readme.txt
	README
	C:\Windows\Notepad.exe
	C:\Windows\
);

{
	package Local::Stringifier;
	use overload q[""], sub { $_[0][0] };
	sub new { bless \@_, shift }
}

push @filenames, Local::Stringifier->new(__FILE__);

ok !is_filename([]), 'is_filename ARRAY';
ok !is_filename(undef), 'is_filename undef';
ok !is_filename(''), 'is_filename empty string';

if ($] >= 5.010)
{
	eval q[
		ok(is_filename, "is_filename $_") for @filenames;

		ok not([]    ~~ FileName), 'ARRAY ~~ FileName';
		ok not(undef ~~ FileName), 'undef ~~ FileName';
		ok not(''    ~~ FileName), 'empty string ~~ FileName';

		for (@filenames)
			{ ok $_ ~~ FileName, "$_ ~~ FileName" };
	];
}

done_testing();
