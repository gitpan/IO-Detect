use strict;
use Test::More;
BEGIN {
	eval "use Path::Class 'file'; 1"
	or plan skip_all => "Need Path::Class for this test.";
};

use IO::Detect;
plan tests => 3;

$_ = file('Makefile.PL');

ok not(is_filehandle), "is_filehandle";
ok is_filename, "is_filehandle";
ok not(is_fileuri), "is_fileuri";

