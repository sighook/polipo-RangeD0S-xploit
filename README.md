Polipo malformed Range header denial of service
===============================================

Summary
-------

This repository contains a small proof-of-concept demonstrating a
denial-of-service condition in **Polipo**, a lightweight caching web
proxy.  The issue is triggered by a malformed `Range` header, which
leads to an assertion failure and process termination.

The behavior is tracked under the following CVEs:

- CVE-2020-36420
- CVE-2021-38614

The issue affects all known Polipo versions, as the assertion is
present in the common request-handling code path.

Technical background
--------------------

Polipo does not correctly validate `Range` headers before using their
values.  When presented with an invalid range where the end offset is
smaller than the start offset, for example:

```
Range: bytes=3-2
```

the proxy evaluates the following assertion in `server.c`:

```c
assert(from >= 0 && (to < 0 || to > from));
```

Since the condition is violated, Polipo aborts immediately.
This results in a reliable denial-of-service without authentication.

Proof of concept
----------------

The included Perl script opens a TCP connection to the target Polipo
instance and sends a minimal HTTP request containing the malformed
`Range` header.  No special libraries or frameworks are used; the
script relies on raw sockets to keep the behavior explicit and easy to
reason about.

The intent of the PoC is to demonstrate:

- Awareness of HTTP request parsing behavior
- Identification of missing input validation
- Understanding of how assertion failures translate into availability
  issues

Usage
-----

```sh
perl polipo-range-dos.pl <host> <port>
```

Example:

```sh
perl polipo-range-dos.pl 127.0.0.1 8123
```

If the request is processed, the Polipo process terminates due to the
failed assertion.

Impact
------

- Remote, unauthenticated denial of service
- Immediate termination of the Polipo proxy process
- Service requires restart or supervision to recover

There is no memory corruption or code execution involved.

Notes on mitigation
-------------------

Polipo is effectively unmaintained.  Practical mitigations include
replacing it with a maintained proxy or filtering malformed `Range`
headers upstream.  Some downstream distributions may carry defensive
patches.

Legal and ethical note
----------------------

This code is provided for documentation, research, and defensive
security work.  It should only be used against systems you own or have
permission to test.

Author
------

Alexandr Savca
<mailto:alexandr.savca89@gmail.com>
