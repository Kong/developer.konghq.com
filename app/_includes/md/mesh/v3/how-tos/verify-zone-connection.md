Confirm the zone is connected to your global control plane:

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **example-cp**.
1. Confirm that `zone-1` appears in the list of zones with an **Online** status.

If it doesn't, check the zone control plane logs, outbound access to the KDS address, the control
plane ID, and the system account's `Connector` role and token.

A connected zone confirms configuration connectivity only. It does not demonstrate workload
mTLS or application permissions.
