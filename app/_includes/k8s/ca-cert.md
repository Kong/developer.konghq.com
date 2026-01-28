Operator needs certificate authority to sign certificate for mTLS communication between Control Plane and Data Plane.
It's handled automatically by Helm chart, in case you need to provide a custom CA certificate, check the section `certificateAuthority`
in the `values.yaml` of the Helm chart to learn how to create and reference your own CA certificate.