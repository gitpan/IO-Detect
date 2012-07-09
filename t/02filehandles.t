# These tests are largely stolen from Greg Bacon's answer to the following StackOverflow question...
# http://stackoverflow.com/questions/3214647/what-is-the-best-way-to-determine-if-a-scalar-holds-a-filehandle
#

use FileHandle;
use IO::File;
use IO::Socket::INET;

use IO::Detect qw( is_filehandle FileHandle );

use Test::More;

plan skip_all => "only works on Linux" unless $^O =~ /linux/i;

my $SLEEP = 5;
my $FIFO  = "/tmp/myfifo";

unlink $FIFO;
my $pid = fork;
die "$0: fork" unless defined $pid;
if ($pid == 0) {
	system("mknod", $FIFO, "p") == 0 or die "$0: mknod failed";
	open my $fh, ">", $FIFO;
	sleep $SLEEP;
	exit 0;
}
else {
	sleep 1 while !-e $FIFO;
}

my @handles = (
	[0, "1",           1],
	[0, "hashref",     {}],
	[0, "arrayref",    []],
	[0, "globref",     \*INC],
	[1, "in-memory",   do {{ my $buf; open my $fh, "<", \$buf; $fh }}],
	[1, "FH1 glob",    do {{ open FH1, "<", "/dev/null"; *FH1 }}],
	[1, "FH2 globref", do {{ open FH2, "<", "/dev/null"; \*FH2 }}],
#	[1, "FH3 string",  do {{ open FH3, "<", "/dev/null"; "FH3" }}],
	[1, "STDIN glob",  \*STDIN],
	[1, "plain read",  do {{ open my $fh, "<", "/dev/null"; $fh }}],
	[1, "plain write", do {{ open my $fh, ">", "/dev/null"; $fh }}],
	[1, "FH read",     FileHandle->new("< /dev/null")],
	[1, "FH write",    FileHandle->new("> /dev/null")],
	[1, "I::F read",   IO::File->new("< /dev/null")],
	[1, "I::F write",  IO::File->new("> /dev/null")],
	[1, "pipe read",   do {{ open my $fh, "sleep $SLEEP |"; $fh }}],
	[1, "pipe write",  do {{ open my $fh, "| sleep $SLEEP"; $fh }}],
	[1, "FIFO read",   do {{ open my $fh, "<", $FIFO; $fh }}],
	[1, "socket",      IO::Socket::INET->new(LocalAddr => sprintf('localhost:%d', 10000 + rand 20000))],
);

plan tests => 2 * scalar @handles;

foreach (@handles)
{
	my ($truth, $label, $fh) = @$_;
	
	if ($truth)
	{
		ok is_filehandle($fh), "positive for $label"
	}
	else
	{
		ok !is_filehandle($fh), "negitive for $label"
	}
}

foreach (@handles)
{
	my ($truth, $label, $fh) = @$_;
	
	if ($truth)
	{
		ok($fh ~~ FileHandle, "smart match positive for $label");
	}
	else
	{
		ok(not($fh ~~ FileHandle), "smart match negitive for $label");
	}
}
