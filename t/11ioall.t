use strict;
use Test::More;
BEGIN {
	eval "use IO::All 'io'; 1"
	or plan skip_all => "Need IO::All for this test.";
};

use IO::Detect;
plan tests => 3;

$_ = io('Makefile.PL');

ok is_filehandle, "is_filehandle";
ok is_filename, "is_filehandle";
ok not(is_fileuri), "is_fileuri";

