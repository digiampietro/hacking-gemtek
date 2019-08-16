#!/usr/bin/perl -w
# read a serial terminal log with the output of the U-Boot command
# nand page xx
# and convert the hex output in a binary file, loggin the "nand page command"
#

use Getopt::Std;

getopts('voh');

$logicpage = 0;
$ignorepage= 0;
$nbytes=0;

sub usage {
    print "usage: $ARGV[0] [-v] [-o] [-h]\n";
    print "     -v  verbose\n";
    print "     -o  include oob data in output\n";
    print "     -h  this help\n";
}

if ($opt_h) {
    usage();
    exit;
}

while (<>) {
    if (/nand\s+page\s+([0-9a-f]+)/) {
	$filepage=hex($1);
	$ignorepage=0;
	if ($opt_v) {print STDERR "Reading page $1\n";}
	if ($filepage > $logicpage) {
	    die "ERROR expecting nand dump of page $logicpage, got page $filepage\n";
	}
	if ($filepage < $logicpage) {
	    print STDERR "WARNING expecting page $logicpage, got already dumped page $filepage, IGNORING\n";
	    $ignorepage=1;
	}
	$logicpage++ unless $ignorepage;
    }
    if ((/oob:/) && (! $opt_o)) {
	<>;
	if ($opt_v) {print STDERR "skipping oob data\n";}
	<>;
	if ($opt_v) {print STDERR "skipping oob data\n";}
	next;
    }
    if (/([0-9a-f][0-9a-f]\s){31}[0-9a-f][0-9a-f]/) {
	#print "$&\n";
	@l=split;
	$linebytes=0;
	unless ($ignorepage) {
	    for $i (@l) {
		print chr(hex($i));
		$linebytes++;
	    }
	    if ($linebytes != 32) {
		die "ERROR at page $filepage, expecting 32 bytes per line, got $linebytes \n";
	    }
	    $nbytes+=$linebytes;
	}
    }
}

if ($logicpage != 65536) {
    die "ERROR expecting 65536 pages, got ",$filepage+1," pages \n";
}

$bytes128Mb= 128 * 1024 * 1024;
$bytes128Mb_oob=$bytes128Mb + ($bytes128Mb/2048 * 64);
if ($opt_o) {
    $totbytes=$bytes128Mb_oob;
} else {
    $totbytes=$bytes128Mb;
}

if ($nbytes == $totbytes) {
    print STDERR "SUCCESS $logicpage pages dumped, $nbytes bytes\n";
} else {
    print STDERR "ERROR expecting $totbytes got $nbytes\n";
}
