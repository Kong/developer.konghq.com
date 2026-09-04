In {{site.mesh_product_name}}, there are two identity concepts:

* [Identity](/mesh/v2/concepts/#identity): A workload identity is the name encoded in its certificate, and this identity is valid only if the certificate is signed by a trust.
* [Trust](/mesh/v2/concepts/#trust): Trust defines which identities you accept as valid through trusted certificate authorities (CA) that issue those identities. Each trust belongs to a trust domain, and a [mesh](/mesh/v2/concepts/#mesh) can contain multiple trusts.
