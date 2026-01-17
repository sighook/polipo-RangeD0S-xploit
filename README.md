# Polipo malformed Range header vulnerabilities

## Overview

This repository documents issues in **Polipo**, a lightweight caching
web proxy, related to incorrect handling of malformed HTTP `Range`
headers.  The same input class exposes two distinct failure modes,
tracked under separate CVEs due to their different impact.

Polipo is effectively unmaintained, but the affected code remains
relevant for historical analysis and for understanding common failure
patterns in HTTP parsing logic.

Associated CVEs:

* CVE-2020-36420
* CVE-2021-38614

## Technical summary

Polipo does not consistently validate byte ranges before using them in
later processing stages.  When presented with an invalid range such
as:

```
Range: bytes=3-2
```

internal assumptions about ordering and size are violated.  Depending
on the execution path, this results in either an assertion failure or
a memory safety violation.

### CVE-2020-36420: assertion-triggered denial of service

In one code path, Polipo evaluates the following assertion in
`server.c`:

```c
assert(from >= 0 && (to < 0 || to > from));
```

For malformed ranges where `to < from`, this assertion fails and the
process aborts immediately.  This is a reliable, remote,
unauthenticated denial of service.

### CVE-2021-38614: heap buffer overflow

In a separate code path, the same class of malformed input leads to
inconsistent buffer sizing.  A heap buffer is allocated based on one
interpretation of the range, then written past its boundary during
later processing.

When built with AddressSanitizer, this manifests as a heap buffer
overflow:

* write past the end of a heap allocation
* immediate abort under sanitizers
* silent memory corruption on non-sanitized builds

While no practical code execution vector is demonstrated, this is a
genuine memory safety violation and therefore tracked as a distinct
CVE.

## Proof of concept

The included Perl script demonstrates the malformed `Range` header
trigger using a minimal raw TCP client.  It is intentionally simple
and avoids frameworks in order to keep the behavior explicit and
reproducible.

Usage:

```sh
perl polipo-range-dos.pl <host> <port>
```

If the request is processed, the Polipo process will terminate due to
either an assertion failure or memory corruption, depending on build
configuration and execution path.

## Impact

* Remote, unauthenticated denial of service
* Process termination
* Potential heap memory corruption (CVE-2021-38614)

No authentication or special configuration is required beyond access
to the listening proxy port.

## Notes on mitigation

Polipo is no longer actively maintained. Practical mitigations
include:

* Replacing Polipo with a maintained proxy implementation
* Filtering malformed `Range` headers upstream
* Applying downstream patches, where available

## Scope and intent

This repository is provided for documentation, analysis, and defensive
security research.  It is intended to illustrate how insufficient
input validation can lead to both logic-level failures and memory
safety issues.

## Author

Alexandr Savca
[alexandr.savca89@gmail.com](mailto:alexandr.savca89@gmail.com)
