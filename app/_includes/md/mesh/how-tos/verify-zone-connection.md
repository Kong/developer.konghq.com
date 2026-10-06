In [Service Mesh](https://cloud.konghq.com/mesh-manager), open your global control plane and
confirm that `zone-1` is online. If it is not, check the zone control plane logs, outbound access
to the KDS address, the control plane ID, and the system account's `Connector` role and token.

A connected zone confirms configuration connectivity only. It does not demonstrate workload
mTLS or application permissions.
