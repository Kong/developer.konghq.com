Operator needs certificate authority to sign certificate for mTLS communication between Control Plane and Data Plane.
It's handled automatically by Helm chart, in case of need to provide custom CA certificate, check section `certificateAuthority`
in the `values.yaml` of the Helm chart to learn how to create and refer your own CA certificate.