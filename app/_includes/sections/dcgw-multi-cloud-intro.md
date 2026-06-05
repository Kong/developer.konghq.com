A single {{site.konnect_short_name}} control plane can manage Dedicated Cloud Gateway deployments across AWS, Azure, and GCP simultaneously.
Multi-cloud deployments are common in enterprise environments for high availability, regulatory requirements, or because upstream services are distributed across providers.

When deploying across multiple cloud providers, you'll need to decide how API consumers discover and reach each deployment.
{{site.konnect_short_name}} doesn't provide cross-cloud private networking.
If a gateway in one cloud must reach backends in another, you're responsible for implementing that connectivity using your cloud provider's tools (for example, Transit Gateway, ExpressRoute, and Direct Connect).