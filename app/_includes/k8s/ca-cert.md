{{site.operator_product_name}} needs a certificate authority to sign the certificate for mTLS communication between the control plane and the data plane.
This is handled automatically by the Helm chart. If you need to provide a custom CA certificate, refer to the `certificateAuthority` section 
in the `values.yaml` of the Helm chart to learn how to create and reference your own CA certificate.