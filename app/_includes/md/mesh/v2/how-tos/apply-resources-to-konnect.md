1. Export your {{site.konnect_short_name}} region:

   ```bash
   export KONNECT_REGION='us'
   ```

1. Configure `kumactl` to target the {{site.konnect_short_name}}-managed global control plane. This points `kumactl` at your control plane's Mesh API and authenticates with your {{site.konnect_short_name}} token:

   ```bash
   kumactl config control-planes add \
     --name konnect \
     --address https://$KONNECT_REGION.api.konghq.com/v1/mesh/control-planes/$CONTROL_PLANE_ID/api \
     --headers "authorization=Bearer $KONNECT_TOKEN" \
     --overwrite
   ```

1. Apply the exported resources to the {{site.konnect_short_name}} global control plane:

   ```bash
   kumactl apply -f resources.yaml
   ```
