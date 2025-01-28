# Kong Gateway Security

## What does it mean to secure Kong Gateway?

Kong employs various compliance, technological, and physical security constraints on all their products. You can see more about these security provisions on the [Kong Compliance page](https://konghq.com/compliance).

In addition to these compliance measures, you can further secure your Kong Gateway by configuring specific objects, like what is logged or the [Admin API](). Security is also a framework within the system, so there are certain best practices you can employ, like authorization and authentication or dividing entities into Workspaces so users only have access to the entities they need to configure.

## Securing the platform (bad title, rework)

* Securing the Admin ApI
* Removing stuff from KG logs for security reasons (GDPR)
* Network/ports (feels like it belongs here more)

## Authentication and authorization

* RBAC
* Super Admin/Admin
* Network/Ports

## Data encryption

Kong Gateway provides both vault secret management as well as encryption using keyring, key set, and keys. 

* **Secrets:** If you are storing sensitive information, like API keys, passwords, or certificates, you should use secret management via the Vaults entity or environment variables. Kong Gateway can store secrets in memory or retrieve them from a third-party vault. Kong Gateway can also rotate your secrets for you if you use the Vault entity, or you can choose to rotate your keys by using your third-party vault's settings.
* **Keys:** Keys, Key Sets, and Keyring can be used to encrypt data. Add more.

* Secrets management
    * Vaults
    * env var
    * secret rotation
* Key ring
* Key Set
* Keys

## Vulnerability management

* Vuln policy
* Bugs

## Monitoring and logging

Help identify attacks

* KG logs
* Logging plugins:
    * Prometheus
    * Datadog
    * Traceable
    * Loggly

## API security

<!--separate landing page????--->

Secure API traffic.

* Require APIs to use HTTPS (how????)
* Authentication plugins
* Rate limiting (Ddos)
* Monitoring and logging (of APIs though? not KG?)
* encrypt data in transit (JWT plugin: message sent by consumer = message that was recieved)
* encrypt data at rest (keyring/keys?)
* Pen testing/debugging/etc Insomnia realm
* Validate and sanitize input to prevent injection attacks (Injection Protection plugin)
* Reduce risk by inventory and management (Service Catalog + API management platform)
* API policy management and enforcement (Scorecards)