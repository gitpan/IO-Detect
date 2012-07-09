use Test::More tests => 2;
use IO::Detect ducktype => { -as => 'can_dump', methods => ['Dump'] };

use Data::Dumper;
use IO::Handle;

ok  can_dump(Data::Dumper->new([]));
ok !can_dump(IO::Handle->new);

