After the migration, you can move the client address from your retained Service to the {{ site.operator_product_name_short }}-managed Service.
This operation is optional, separate from the migration, and depends on your load balancer platform.

After the migration, the client address lives on a Service that no chart or {{ site.operator_product_name }} manages.
{{ site.operator_product_name_short }} publishes its own `ClusterIP` in the `status` of your Ingress and Gateway resources, and not your client address.

If you move the address to the {{ site.operator_product_name_short }}-managed Service, {{ site.operator_product_name_short }} manages the whole setup.
Whether this is worth doing depends on your platform:

{% table %}
columns:
  - title: Proxy Service type
    key: type
  - title: Recommendation
    key: recommendation
rows:
  - type: "`ClusterIP` or `NodePort`"
    recommendation: "**Not applicable.** Your clients resolve the Service by name, and the new Service has a different name. Keep the Service you have."
  - type: Self-managed load balancer, such as MetalLB
    recommendation: "**Optional.** Reassignment is a local operation and completes in less than a second."
  - type: AWS
    recommendation: "**Don't attempt.** A load balancer's lifecycle is bound to the Service that created it, and AWS has no reassignment operation. Deleting the Service deletes the load balancer, and the replacement load balancer has a different hostname. To pin elastic IPs, you must first release them from the old load balancer."
  - type: Azure
    recommendation: "**Don't attempt.** You can't attach a static public IP to two Services at once. The move is a release followed by a reassignment, and reconciliation takes from tens of seconds to minutes."
  - type: Other cloud providers
    recommendation: Before you try this, check that your provider supports moving the address between Services. If you aren't sure, keep the Service you have.
{% endtable %}

If you keep the existing Service, the migration outcome stays the same.
Continue to manage its manifest yourself, and account for the different status address in any tooling that reads it.

If your platform supports the move, request the address on the new Service **first**, and let the request stay pending.
Then release the address from the old Service.
In this order, the load balancer assigns the address to the new Service as soon as the old Service releases it.

1. Request the address on the {{ site.operator_product_name_short }}-managed Service.
   Replace the annotation with the equivalent annotation for your load balancer:

   ```bash
   kubectl patch gatewayconfiguration -n "${NAMESPACE}" kong-migrated --type merge -p \
     '{"spec":{"dataPlaneOptions":{"network":{"services":{"ingress":{
        "type":"LoadBalancer",
        "annotations":{"metallb.universe.tf/loadBalancerIPs":"192.0.2.10"}}}}}}}'
   ```

1. Wait until the new Service has the `LoadBalancer` type and a pending address.

1. Release the address from the old Service:

   ```bash
   kubectl patch svc -n ${NAMESPACE} ${PROXY_SERVICE} --type json \
     -p '[{"op":"replace","path":"/spec/type","value":"ClusterIP"}]'
   ```

1. Check that the new Service has the address, and verify traffic.
   Then delete the old Service.
