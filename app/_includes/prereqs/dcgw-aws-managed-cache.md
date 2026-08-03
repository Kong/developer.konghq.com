This tutorial requires an AWS managed cache already attached to a Ready Dedicated Cloud Gateway control plane.

If you don't have one configured yet, create one with Terraform:

<!--vale off-->
```hcl
echo '
resource "konnect_gateway_control_plane" "test_cp" {
  name         = "CGW Control Plane"
  cloud_gateway = true
}

resource "konnect_cloud_gateway_addon" "managed_cache" {
  name = "managed-cache"
  owner = {
    control_plane = {
      control_plane_id  = konnect_gateway_control_plane.test_cp.id
      control_plane_geo = "us"
    }
  }
  config = {
    managed_cache = {
      capacity_config = {
        tiered = {
          tier = "micro"
        }
      }
    }
  }
}
' >> main.tf
```
<!--vale on-->

```bash
terraform apply -auto-approve
```

For sizing recommendations, a control plane group setup, or the full walkthrough, see [Configure an AWS managed cache for a Dedicated Cloud Gateway control plane](/dedicated-cloud-gateways/aws-managed-cache-control-plane/) or [Configure an AWS managed cache for a Dedicated Cloud Gateway control plane group](/dedicated-cloud-gateways/aws-managed-cache-control-plane-group/).
