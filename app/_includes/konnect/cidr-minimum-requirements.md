{:.danger}
> **You cannot edit an existing Dedicated Cloud Gateway network CIDR:** To change a network's CIDR, recreate the network with the new CIDR.

Before creating a Dedicated Cloud Gateway network, choose the CIDR range you want to use.
A CIDR block defines the range of IP addresses available for your Dedicated Cloud Gateway. 
If you're configuring private network connectivity, this CIDR block **must not** overlap with CIDR blocks assigned in your own cloud service provider networks to prevent conflicts.
The CIDR block must also be large enough to accommodate all Kong-managed infrastructure provisioned inside the network such as the data plane nodes, the DNS proxy, internal load balancers, and other components.

Keep the following requirements in mind when choosing your network CIDR range:
* **Prefix length:** The CIDR block must have a prefix length between `/16` and `/23`. `/23` blocks support a maximum of 2 availability zones.
* **Private IP Range:** The entire CIDR block must fall within one of these private IP ranges:
  * 10.0.0.0/8
  * 100.64.0.0/10
  * 172.16.0.0/12
  * 192.168.0.0/16
  * 198.18.0.0/15
* **No overlap with existing ranges:** Your CIDR block **must not** overlap with any IP ranges already in use by your organization. Overlapping ranges can prevent network peering from functioning correctly.
* **No overlap with reserved CIDR blocks:** Your CIDR block must not overlap with these reserved ranges:
  * 10.100.0.0/16
  * 172.17.0.0/16

{:.info}
> **Acceptable CIDR examples:**
> * 10.4.0.0/16
> * 100.68.0.0/20
> * 172.20.0.0/22
> * 192.168.128.0/18
> * 198.18.0.0/16

The number of availability zones (AZs) you plan to use determines the minimum CIDR range for your Dedicated Cloud Gateway network.
Keep the following in mind:
* Cloud service providers enforce a minimum subnet mask of /28 (16 IPs) and a maximum of /16 (65,536 IPs) for any subnet.
* The following table reflects the minimum recommended CIDR sizes for Dedicated Cloud Gateway deployments to ensure sufficient IP address space for the required infrastructure.
* Selecting a larger CIDR block provides more flexibility for future growth and expansion.

The following table details the minimum CIDR sizes by AZ count:

<!--vale off-->
{% table %}
columns:
  - title: Number of AZs
    key: az_count
  - title: Minimum CIDR
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

How many IPs are usable depends on whether you're using a public or private subnet, your network's CIDR range, and AZ count.
* **Public subnets:** Kong reserves about 50 IPs in total (used by Kong's internal services and cloud provider reserves).
* **Private subnets:** The cloud provider your Dedicated Cloud Gateway is deployed on reserves 5 IPs. It cannot use subnets that have fewer than 8 IPs, so Kong reserves about 15 IPs per AZ.

