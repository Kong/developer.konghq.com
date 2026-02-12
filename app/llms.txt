# LLMs.txt for developer.konghq.com

This file provides a structured list of all relevant documentation pages for Kong’s Developer Portal, organized by product area.

Each link includes a concise description to help Large Language Models (LLMs) and documentation crawlers understand its purpose and relevance. Use this file to:

- Improve semantic indexing across LLMs and AI-powered search tools
- Enable structured navigation and grouping by product function
- Maintain up-to-date visibility into the developer-facing content for Kong Gateway, Konnect, Mesh, plugins, and more

---

**Groupings include:**
- Kong Gateway
- Konnect Platform
- Dev Portal
- AI Gateway & Event Gateway
- decK & Inso CLI
- Kubernetes & Operator
- Mesh
- Terraform
- Service Catalog
- Plugins (coming soon)

Each section uses the format:  
**[Link Title](https://url): Description**

---

## Kong Gateway

- [Kong Gateway](https://developer.konghq.com/gateway/): Cloud-native API gateway enabling secure, observable, and performant service communication.
- [Admin API](https://developer.konghq.com/admin-api/): REST API for configuring core Gateway entities like services, routes, and plugins.
- [Install Kong Gateway](https://developer.konghq.com/gateway/install/): Installation guides for Kong Gateway across environments (Docker, Linux, Konnect).
- [Secure the Admin API](https://developer.konghq.com/gateway/secure-the-admin-api/): Instructions for applying RBAC, SSL, and other protections to the Admin API.
- [Gateway Security](https://developer.konghq.com/gateway/security/): Overview of built-in security features: mTLS, JWT, secrets management, and more.
- [Audit Logs](https://developer.konghq.com/gateway/audit-logs/): Details on Gateway auditing and log forwarding capabilities.
- [Secrets Management](https://developer.konghq.com/gateway/secrets-management/): Manage sensitive configuration (tokens, certs) using vaults and keyrings.
- [Keyring](https://developer.konghq.com/gateway/keyring/): Configure encrypted keyrings for secret encryption at rest.
- [Logs](https://developer.konghq.com/gateway/logs/): Log formats, destinations, and structured logging options.
- [Version Support Policy](https://developer.konghq.com/gateway/version-support-policy/): Policy detailing supported Kong Gateway versions and upgrade timelines.
- [Vulnerabilities](https://developer.konghq.com/gateway/vulnerabilities/): CVEs and disclosed security vulnerabilities affecting Kong Gateway.

---

## Konnect Platform (Hosted Control Plane)

- [Konnect Overview](https://developer.konghq.com/konnect/): Managed API lifecycle platform for routing, analytics, developer onboarding, and mesh control.
- [Konnect APIs](https://developer.konghq.com/konnect-api/): Public API reference for interacting with Konnect resources.
- [Konnect Platform - Authentication](https://developer.konghq.com/konnect-platform/authentication/): Configure SSO, social login, MFA, and passwordless auth for Dev Portals and teams.
- [Konnect Platform - Audit Logs](https://developer.konghq.com/konnect-platform/audit-logs/): Audit trail of changes to Konnect services and platform configuration.
- [Konnect Platform - Teams & Roles](https://developer.konghq.com/konnect-platform/teams-and-roles/): Define RBAC roles and manage access permissions across workspaces.
- [Konnect Platform - Geos](https://developer.konghq.com/konnect-platform/geos/): Data residency options across supported regions.
- [Konnect Platform - Account Management](https://developer.konghq.com/konnect-platform/account/): Manage billing, identity provider configuration, and support contacts.
- [Konnect Platform - SSO](https://developer.konghq.com/konnect-platform/sso/): Configure enterprise-level SSO with third-party identity providers.

---

## Dev Portal

- [Dev Portal Overview](https://developer.konghq.com/dev-portal/): Documentation portal for onboarding API consumers and managing access.
- [Access & Approval](https://developer.konghq.com/dev-portal/access-and-approval/): Grant access to portal users and review approval workflows.
- [Analytics](https://developer.konghq.com/dev-portal/analytics/): View API usage insights by developer or app.
- [APIs](https://developer.konghq.com/catalog/apis/): List and publish APIs available through the developer portal.
- [Application Registration](https://developer.konghq.com/dev-portal/application-registration/): Register and manage consumer apps, including credentials.
- [Auth Strategies](https://developer.konghq.com/dev-portal/auth-strategies/): Configure OAuth2, API key, and custom auth for your portal.
- [Breaking Changes](https://developer.konghq.com/dev-portal/breaking-changes/): How to handle backward-incompatible API changes.
- [Custom Domains](https://developer.konghq.com/dev-portal/custom-domains/): Configure branded domains for your developer portals.
- [Developer Signup](https://developer.konghq.com/dev-portal/developer-signup/): Configure signup workflows and required fields.
- [Dynamic Client Registration](https://developer.konghq.com/dev-portal/dynamic-client-registration/): Enable dynamic OAuth2 registration from consumer applications.
- [Pages & Content](https://developer.konghq.com/dev-portal/pages-and-content/): Manage CMS-like pages including markdown and templated content.
- [Portal Customization](https://developer.konghq.com/dev-portal/customizations/dev-portal-customizations/): Themes, colors, fonts, and structural overrides for branding.
- [Portal Settings](https://developer.konghq.com/dev-portal/portal-settings/): Configure portal-level security, appearance, and defaults.
- [Security Settings](https://developer.konghq.com/dev-portal/security-settings/): Security and privacy features available per portal.
- [SSO](https://developer.konghq.com/dev-portal/sso/): SSO configuration for portal login via identity providers.
- [Team Mapping](https://developer.konghq.com/dev-portal/team-mapping/): Map internal teams to dev portal access and permissions.

---

## decK (Declarative Configuration)

- [decK Overview](https://developer.konghq.com/deck/): Command-line tool for managing Kong Gateway configurations in a GitOps workflow.
- [API Ops with decK](https://developer.konghq.com/deck/apiops/): Best practices and pipelines for implementing API operations via decK and CI/CD.
- [decK Get Started](https://developer.konghq.com/deck/get-started/): Setup and usage guide for bootstrapping a decK-managed Kong instance.
- [Reset Gateway with decK](https://developer.konghq.com/deck/gateway/reset/): Reset a Gateway's configuration using decK commands.
- [decK Reference - Entities](https://developer.konghq.com/deck/reference/entities/): Documentation of all supported Kong entities and how they map to decK config.

---

## Inso CLI

- [Inso CLI Overview](https://developer.konghq.com/inso-cli/): Command-line tool for running tests, linting specs, and syncing API designs from Insomnia.

---

## Event Gateway

- [Event Gateway Overview](https://developer.konghq.com/event-gateway/): Event-driven gateway service that allows publish-subscribe API patterns.
- [Get Started with Event Gateway](https://developer.konghq.com/event-gateway/get-started/): Initial configuration guide for deploying and testing Event Gateway flows.

---

## AI Gateway

- [AI Gateway Overview](https://developer.konghq.com/ai-gateway/): A new gateway optimized for AI-native APIs, semantic routing, caching, and policy enforcement.
- [Get Started with AI Gateway](https://developer.konghq.com/ai-gateway/get-started/): Quickstart for AI Proxy plugins and OpenAI integrations in API routing.

---

## Service Catalog

- [Catalog Overview](https://developer.konghq.com/catalog/): Repository of services, dependencies, and metadata for internal APIs.
- [Catalog - Datadog Integration](https://developer.konghq.com/catalog/integrations/datadog/): Link Datadog monitors and dashboards to services.
- [Catalog - GitHub Integration](https://developer.konghq.com/catalog/integrations/github/): Link GitHub repos to service records for ownership and CI/CD metadata.
- [Catalog - GitLab Integration](https://developer.konghq.com/catalog/integrations/gitlab/): Sync GitLab projects and activity to the service registry.
- [Catalog - PagerDuty Integration](https://developer.konghq.com/catalog/integrations/pagerduty/): Link on-call schedules and incident metadata to services.
- [Catalog - SwaggerHub Integration](https://developer.konghq.com/catalog/integrations/swaggerhub/): Associate API documentation directly with SwaggerHub definitions.
- [Catalog - Traceable Integration](https://developer.konghq.com/catalog/integrations/traceable/): Integrate service metadata with Traceable AI observability.
- [Scorecards](https://developer.konghq.com/catalog/scorecards/): Configurable quality/security checks and compliance evaluations for services.

---

## Kong Mesh

- [Kong Mesh Overview](https://developer.konghq.com/mesh/): Enterprise service mesh built on Kuma with full support for multi-zone, zero-trust, and policy-based traffic control.
- [About Mesh](https://developer.konghq.com/mesh/service-mesh/): Overview of Mesh use cases, architecture, and deployment models.
- [Mesh Concepts](https://developer.konghq.com/mesh/concepts/): Core concepts such as meshes, zones, dataplanes, and control planes.
- [Mesh Architecture](https://developer.konghq.com/mesh/architecture/): Internal architecture and interaction between control and data planes.
- [Mesh CLI](https://developer.konghq.com/mesh/cli/): Reference guide for using the `kumactl` CLI to manage Kong Mesh.
- [Kubernetes Support](https://developer.konghq.com/mesh/kubernetes/): Kong Mesh installation and operation within Kubernetes clusters.
- [Universal Mode](https://developer.konghq.com/mesh/universal/): Running Kong Mesh outside of Kubernetes in a VM-based environment.
- [Ingress & Gateway Delegation](https://developer.konghq.com/mesh/ingress/): Routing external traffic into the mesh.
- [Policies Intro](https://developer.konghq.com/mesh/policies-introduction/): Overview of available traffic policies and how to apply them.
- [All Policies](https://developer.konghq.com/mesh/policies/): Complete index of supported traffic, security, and telemetry policies in Kong Mesh.
- [RBAC](https://developer.konghq.com/mesh/rbac/): Role-based access control configuration and examples.
- [Authentication with API Server](https://developer.konghq.com/mesh/authentication-with-the-api-server/): Security and credential options for the control plane.
- [Multi-zone Authentication](https://developer.konghq.com/mesh/multi-zone-authentication/): Configuring security between zones in multi-region deployments.
- [License Info](https://developer.konghq.com/mesh/license/): Licensing and entitlement details.
- [Changelog](https://developer.konghq.com/mesh/changelog/): Release notes and upgrade history for Kong Mesh.
- [Upgrade Guide](https://developer.konghq.com/mesh/upgrade/): Instructions for safely upgrading Kong Mesh instances.
- [Support Policy](https://developer.konghq.com/mesh/support-policy/): Version lifecycle and support guarantees.

---

## Kubernetes Ingress Controller

- [Ingress Controller Overview](https://developer.konghq.com/kubernetes-ingress-controller/): Kubernetes-native ingress controller powered by Kong Gateway.
- [Install Guide](https://developer.konghq.com/kubernetes-ingress-controller/install/): Step-by-step instructions for installing the controller via Helm or manifests.
- [Gateway API Support](https://developer.konghq.com/kubernetes-ingress-controller/gateway-api/): Implementations of the Kubernetes Gateway API spec.
- [Traffic Splitting](https://developer.konghq.com/kubernetes-ingress-controller/split-traffic/): Canary and A/B testing capabilities via traffic splitting rules.

---

## Kong Operator

- [Operator Overview](https://developer.konghq.com/operator/): Kubernetes controller that automates deployment and configuration of Kong Gateway.
- [Install the Operator](https://developer.konghq.com/operator/get-started/gateway-api/install/): Installation instructions and CRD setup.

---

## Terraform

- [Terraform Provider Overview](https://developer.konghq.com/terraform/): Infrastructure as code support for managing Gateway and Konnect via Terraform.
- [Gateway Authentication How-To](https://developer.konghq.com/terraform/how-to/gateway-authentication/): Example for configuring Gateway authentication via Terraform.