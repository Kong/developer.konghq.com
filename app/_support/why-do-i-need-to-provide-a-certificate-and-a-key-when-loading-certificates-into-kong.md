---
title: Why Kong requires both a certificate and its private key when loading certificates
content_type: support
description: Explains why Kong requires both a certificate and its matching private key when loading certificates, since proving control of the private key is what authenticates the certificate.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why do I need to provide a certificate AND a key when loading certificates into Kong
  a: |
    A certificate alone is public information — proving you actually control the identity it names requires demonstrating possession of the matching private key, by signing or decrypting something only that key can produce. Without the private key, a certificate is useless for authentication, which is why Kong needs both when loading certificates.
related_resources:
  - text: RFC 4346 authenticated key exchange (Appendix F.1.1)
    url: "http://tools.ietf.org/html/rfc4346#appendix-F.1.1"
  - text: RFC 4346 Certificate Verify message (Section 7.4.8)
    url: "http://tools.ietf.org/html/rfc4346#section-7.4.8"
---

## Problem

Why do I need to provide a certificate AND a key when loading certificates into Kong?

## Solution

Certificates on their own are only public pieces of information. What links a public key certificate to the name it contains is the fact that whoever has legitimate control over that name (e.g. the CN or SAN in the cert) also has the private key for it.

Certificates are used to prove the identity of the remote party by challenging the remote party to perform an operation that can only be done with the corresponding private key: signing something (which can be verified with the public key) or deciphering something that was encrypted with the public key. (Both can happen in the SSL/TLS handshake, depending on the cipher suite.)

During the SSL/TLS handshake, the server sends its certificate (in clear) and proves to the client that it has the corresponding private key using an authenticated key exchange.

In the case of mtls, you also want to use client-certificate authentication. It's not enough to send the client certificate during the handshake: the client must also prove it has the private key. Otherwise, anyone who receives that certificate could clone it. The point of using certificates is to prevent any cloning, in such a way that you never have to show your own secret (the private key).

More specifically, the client has to sign the handshake messages in the Certificate Verify message of the TLS handshake so that the server can verify it against the public key sent in the client certificate. Without this step, no client-certificate authentication would be taking place.

If you only have a certificate and not its private key, then that certificate is rendered useless for authentication purposes.

IMPORTANT: Kong never sends the private key to the upstream, it purely uses it to sign messages to prove it is authorized to use that certificate for authentication purposes.

How does Kong use this mechanism?

Kong uses this mechanism in all of its HTTPS communication. Kong can act as a server or a client but the mechanism works the same regardless of which is in use.

If you need Kong to forward a client certificate to an upstream API, then in this case, Kong is acting like a client and the upstream server will verify the sent client certificate with the key exchange mentioned above.

When clients are connecting to Kong via TLS/SSL, Kong is the server in this case and provides the relevant server certificate to the client (Could be the proxy, manager, admin-api etc certificate). Kong will then sign the verification messages with the private key that is provided along with the server certificate in the Kong configuration.
