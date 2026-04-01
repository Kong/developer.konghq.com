Kong Dedicated Cloud Gateway (DCGW) deployments require a Virtual Private Cloud (VPC) with a properly sized CIDR block. The following table outlines the minimum VPC CIDR requirements based on the number of Availability Zones (AZs) you plan to use for your DCGW deployment.

Keep the following in mind:
* Cloud Service Providers enforce a minimum subnet mask of /28 (16 IPs) and a maximum of /16 (65,536 IPs) for any VPC subnet.
* The following table reflects the minimum recommended VPC CIDR sizes for Kong DCGW deployments to ensure sufficient IP address space for the required infrastructure.
* Selecting a larger VPC CIDR block provides more flexibility for future growth and expansion.


The following table details the minimum VPC sizes by AZ count:

<!--vale off-->
{% table %}
columns:
  - title: Number of AZs
    key: az_count
  - title: Minimum VPC CIDR
    key: cidr

rows:
  - az_count: 2
    cidr: "/23 (512 IPs)"
  - az_count: 3
    cidr: "/22 (1,024 IPs)"
  - az_count: 4
    cidr: "/22 (1,024 IPs)"
  - az_count: 5
    cidr: "/21 (2,048 IPs)"
{% endtable %}
<!--vale on-->