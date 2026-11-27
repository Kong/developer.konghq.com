---
title: "Agents"
content_type: reference
layout: reference
permalink: /ai-access-management/agents/
works_on:
  - konnect
tools:
  - konnect-api
  - kongctl

products:
  - ai-gateway
breadcrumbs:
  - /ai-gateway/
  - /ai-access-management/
tags:
  - ai
  - access-control
  - authentication

min_version:
  ai-gateway: '2.3'

description: "Create agents in {{site.ai_gateway}} so that users and other agents can call them through the gateway, and give agents their own identity to call models and MCP servers. Includes common setups and what each option of the New agent form does."

related_resources:
  - text: "Access management concepts"
    url: /ai-access-management/concepts/
  - text: "Virtual keys"
    url: /ai-access-management/virtual-keys/
  - text: "AI Agents"
    url: /ai-gateway/entities/ai-agent/
  - text: "AI Auth Strategies"
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: "Token exchange with the OpenID Connect auth strategy"
    url: /ai-gateway/openid-connect/#token-exchange
  - text: "Principals"
    url: /identity/principals/
  - text: "Route A2A agent traffic through {{site.ai_gateway}}"
    url: /ai-gateway/get-started-with-ai-agent/
  - text: "Roles and permissions"
    url: /ai-management/roles-and-permissions/

faqs:
  - q: Does creating an agent with **New agent** give the agent an identity?
    a: |
      No. **New agent** makes the agent reachable through {{site.ai_gateway}} so that others can call it. To let the agent call models, MCP servers, or other agents with its own identity, give it an [agent identity](/ai-access-management/agents/).
  - q: Can I change an agent's type after I create it?
    a: |
      No. The **Type** of an agent can't be edited in {{site.konnect_short_name}} after creation. To switch between A2A and HTTP, create a new agent with the other type and delete the old one.
  - q: Why does my A2A agent answer `413 Request body too large`?
    a: |
      The request body is larger than the agent's **Max request body size**. {{site.ai_gateway}} reads the body of A2A agent requests to detect A2A operations, and rejects bodies over the limit. Raise the limit, or set it to `0` to remove it. See [Max request body size](#max-request-body-size).
  - q: Why can't I select **Multiple targets**?
    a: |
      Multiple targets for an agent need {{site.ai_gateway}} 2.4 or later. On earlier versions, use **Single URL**.
  - q: Why can't I mark a target as **Failover only**?
    a: |
      The **Consistent hashing** algorithm pins each header value to one target, so it can't use failover targets. Choose another algorithm to use failover targets.
---

An agent is a software system that uses AI to act on its own or on behalf of a user.
When you create an agent in {{site.ai_gateway}}, the gateway becomes its single entry point: users and other agents call the agent through a gateway route instead of contacting it directly.

[Create an agent](#create-an-agent), then choose the setup that matches your use case:

<!-- vale off -->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Setup
    key: setup
rows:
  - usecase: "Users and other agents call your agent"
    setup: |
      * Choose an [auth strategy](#auth-strategy) so that callers authenticate.
      * Optional: [Restrict access with an ACL](#access-control) to the groups that may call the agent.
  - usecase: "Your agent also calls models or MCP servers"
    setup: |
      * Give it an [agent identity](/ai-access-management/agents/).
{% endtable %}
<!-- vale on -->

For example, a support team creates a booking agent deployed to AWS AgentCore so that a support agent can call it.
The booking agent also calls a model and an MCP server, so the team gives it an agent identity.

## Create an agent

When you create an agent, {{site.ai_gateway}} authenticates the agent's callers, applies access rules and [AI Policies](/ai-gateway/entities/ai-policy/), and records the traffic.

An agent is reachable through the gateway as soon as you create it, without a separate step.
The agent belongs to the {{site.ai_gateway}} that's selected in the **Gateway** filter of the agents list, because the form doesn't have its own gateway field.
After the gateway's data planes receive the configuration, callers reach the agent at the data plane host followed by the route's base path, for example `https://<YOUR_DP_HOST>/booking-agent`.
The agent's **Connect** tab shows a sample request.
The sample sends the key in the `Authorization` header, so adjust it if your [auth strategy](#auth-strategy) expects the key in another header or a query parameter.

To create an agent, do the following:

1. In the {{site.konnect_short_name}} sidebar, click **Agents**.
1. From the **Gateway** dropdown menu, select the {{site.ai_gateway}} that callers will use.
1. Click **New agent**.
1. Fill in the **General information**, **Configuration**, **Route**, and **Access** sections.
1. Click **Create**.

{:.warning}
> When an agent doesn't have an auth strategy, any caller whose request matches its route can use the agent.
> The default base path, `/`, matches every request on the gateway.
> Set a specific base path, and choose an [auth strategy](#auth-strategy) for any agent that isn't on a private development gateway.

Only Org Admins can add an agent.
Team Managers and Individual Users can ask an Org Admin to add one with **Request an agent**.
See [Roles and permissions](/ai-management/roles-and-permissions/#agents).

Each option of the form sets a field of the [AI Agent](/ai-gateway/entities/ai-agent/) entity, so you can configure the same agent with the {{site.ai_gateway}} API or kongctl.

### Common configurations

The following table lists common situations and the options of the **New agent** form that address them.
Options that aren't listed keep their defaults.

<!-- vale off -->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: What to set
    key: config
  - title: Why
    key: why
rows:
  - usecase: "**Testing:** You've built an agent, and you want to check that requests through the gateway actually reach it, and you don't want to set up authentication and access rules yet"
    config: |
      * [**Type**](#type): A2A
      * [**Upstream**](#upstream): Single URL
      * [**Base path**](#route): A path for this agent, like `/booking-agent`
    why: "This is the smallest working setup. Use it only on a development gateway."
  - usecase: "Your teams call the agent directly, and you need to see who sends which request"
    config: |
      * [**Type**](#type): A2A
      * [**Auth strategy**](#auth-strategy): A key authentication strategy with [principal mapping](/ai-gateway/entities/ai-auth-strategy/#principal-mapping) enabled
    why: "Each caller uses their own virtual key, so {{site.ai_gateway}} attributes requests to the user or agent that sends them, and callers discover the agent through the gateway."
  - usecase: "Only some teams should be able to call the agent"
    config: |
      * [**Auth strategy**](#auth-strategy): A key authentication strategy with principal mapping enabled
      * [**Access control**](#access-control): **Allow**, with a **Principal group** rule for each team
    why: "The ACL needs to know who the caller is, so it works with the auth strategy. Callers outside the allowed groups are rejected before they reach the agent."
  - usecase: "The agent runs on Amazon Bedrock AgentCore Runtime and rejects the gateway's requests"
    config: |
      * [**Upstream authentication**](#upstream-authentication): AWS IAM (SigV4), with an assumed role
    why: "AgentCore Runtime only accepts requests signed with AWS IAM. An assumed role keeps credentials short-lived and works across accounts."
  - usecase: "You run the agent in several regions, and callers far from it see slow responses"
    config: |
      * [**Upstream**](#upstream): **Multiple targets**, one for each region
      * [**Algorithm**](#choose-an-algorithm): **Lowest latency**
      * **Failover only**: On a standby target in another region
    why: "Each request goes to the fastest region, and the standby takes traffic only if every other target is down."
  - usecase: "You want to try a new version of the agent on a small share of traffic"
    config: |
      * [**Upstream**](#upstream): **Multiple targets**, one for each version
      * [**Algorithm**](#choose-an-algorithm): **Round robin**
      * **Weight**: For example, `90` for the current version and `10` for the new one
    why: "A small share of traffic reaches the new version. Raise its weight as you gain confidence."
  - usecase: "The agent keeps conversations in memory, and replies lose context when requests reach another replica"
    config: |
      * [**Upstream**](#upstream): **Multiple targets**
      * [**Algorithm**](#choose-an-algorithm): **Consistent hashing**
      * **Hash on header**: A header that identifies the session
    why: "Every request of a session reaches the replica that holds its state. Failover targets aren't available with this algorithm."
  - usecase: "The agent doesn't implement A2A, or callers get `400` errors because their bodies aren't JSON"
    config: |
      * [**Type**](#type): HTTP
    why: "{{site.ai_gateway}} proxies requests without parsing them, so bodies that aren't JSON go through."
  - usecase: "The data plane can only reach the agent through a corporate egress proxy"
    config: |
      * [**Upstream**](#upstream): Single URL
      * [**Proxy settings**](#proxy-settings): Your proxy's host and port
    why: "Proxy settings don't work with multiple targets."
  - usecase: "Callers get `413` errors when they send files or long messages to an A2A agent"
    config: |
      * [**Max request body size**](#max-request-body-size): A value larger than your largest message, or `0`
    why: "{{site.ai_gateway}} rejects larger bodies before they reach the agent."
  - usecase: "You need to see what callers send and what the agent answers to debug a conversation"
    config: |
      * [**Log payloads**](#log-payloads): Enabled
    why: "Request and response bodies appear in the output of logging AI Policies. Payloads can contain sensitive data."
  - usecase: "The agent only accepts clients that present a certificate"
    config: |
      * [**Upstream TLS**](#upstream-tls): A **Client certificate**
    why: "{{site.ai_gateway}} presents the certificate to the agent for mutual TLS."
{% endtable %}
<!-- vale on -->

### General information

The **General information** section names the agent and sets how {{site.ai_gateway}} reads its traffic.

#### Display name

The **Display name** is shown in {{site.konnect_short_name}}.
{{site.konnect_short_name}} also gives the agent a name in lowercase with hyphens, like `booking-agent`, which identifies it in the API and in declarative configuration.

#### Type

The **Type** defines whether {{site.ai_gateway}} understands the [Agent-to-Agent (A2A) protocol](https://a2aproject.github.io/A2A/) for this agent.
You can't change it in {{site.konnect_short_name}} after you create the agent.

<!-- vale off -->
{% table %}
columns:
  - title: Type
    key: type
  - title: What {{site.ai_gateway}} does
    key: behavior
  - title: Choose it when
    key: when
rows:
  - type: "**A2A (agent-to-agent)**"
    behavior: |
      Detects A2A operations, rewrites the URLs in the agent's Agent Card so that clients keep calling the agent through the gateway, and records A2A metrics and traces.

      To detect A2A calls, {{site.ai_gateway}} reads and parses JSON request bodies. It rejects a body that isn't valid JSON with a `400` error, and a body larger than **Max request body size** with a `413` error.
    when: "The agent implements the A2A protocol, and you want callers to discover it through the gateway and to see its traffic as A2A tasks and messages."
  - type: "**HTTP**"
    behavior: "Proxies requests to the agent without A2A processing."
    when: "The agent doesn't implement A2A, for example a REST or chat endpoint, or its requests carry bodies that aren't JSON."
{% endtable %}
<!-- vale on -->

For details on A2A processing, see [How A2A traffic flows](/ai-gateway/entities/ai-agent/#how-a2a-traffic-flows).

#### Labels

Labels are key-value pairs, like `team=customer-service`.
They're shown in the **Labels** column of the agents list.

### Configuration

The **Configuration** section defines where {{site.ai_gateway}} sends requests and how it connects to the agent.

#### Upstream

The **Upstream** option defines where {{site.ai_gateway}} sends requests:

<!-- vale off -->
{% table %}
columns:
  - title: Option
    key: option
  - title: What it does
    key: behavior
  - title: Choose it when
    key: when
rows:
  - option: "**Single URL**"
    behavior: "Sends every request to one URL, including scheme, host, port, and path."
    when: "The agent runs as a single deployment, or something else already balances its traffic, like a cloud load balancer."
  - option: "**Multiple targets**"
    behavior: "Balances requests across several replicas of the agent, with optional failover. Requires {{site.ai_gateway}} 2.4 or later."
    when: "You run the agent in more than one place, for example in several regions, as a primary and a standby, or as two versions during a rollout."
{% endtable %}
<!-- vale on -->

When you choose **Multiple targets**, you set the following:

* **Protocol** and **Path prefix:** Shared by all targets. The protocol defaults to HTTPS. The path prefix is prepended to the path of every request sent to the targets.
* **Address:** The host name or IP address of each target, followed by its port.
* **Weight:** The share of traffic each target gets. Use weights to send more traffic to larger replicas, or a small share to a new version.
* **Failover only:** The target takes traffic only when every other target is unhealthy. Keep at least one target that isn't failover only.
* **Algorithm:** How {{site.ai_gateway}} picks a target for each request.

##### Choose an algorithm

The load balancing algorithm should match how your agent behaves:

<!-- vale off -->
{% table %}
columns:
  - title: Algorithm
    key: algorithm
  - title: Choose it when
    key: when
rows:
  - algorithm: "**Round robin**"
    when: "Replicas are interchangeable. Requests rotate across targets, evenly or by weight. This is also the algorithm to use for a weighted rollout."
  - algorithm: "**Least connections**"
    when: "Some requests keep a connection open much longer than others, like long-running tasks or streamed responses."
  - algorithm: "**Lowest latency**"
    when: "Replicas are in different regions, and the fastest one should serve most traffic."
  - algorithm: "**Consistent hashing**"
    when: "The agent keeps session state in memory, so a conversation must stay on the same replica. Set **Hash on header** to a header that identifies the session, like `X-Session-ID`. Requests without the header all go to one target. Failover targets aren't available with this algorithm."
{% endtable %}
<!-- vale on -->

See [Load balancing and failover](/ai-gateway/entities/ai-agent/#load-balancing-and-failover) for more examples.

#### Log payloads

**Log payloads** records request and response bodies in the output of logging AI Policies.
It's disabled by default.
Enable it when you need to see what callers send and what the agent answers, for example to debug a conversation.
Payloads can contain sensitive data, so only enable it if your logging pipeline can handle that data.

When **Log payloads** is enabled, **Logging max payload size** truncates logged payloads at that size, in bytes.
Lower it if payloads use too much log storage, or raise it if they're cut off before the part you need.

#### Max request body size

**Max request body size** is the largest request body, in bytes, that {{site.ai_gateway}} reads for an A2A agent.
Larger bodies are rejected with a `413` error.
Raise it when callers send large messages, for example with file content included in the message.
Set it to `0` to remove the limit.
The data plane's `client_max_body_size` still applies.

#### Upstream authentication

**Upstream authentication**, in the section's **Advanced fields**, signs requests to the agent with AWS IAM (SigV4).
It's separate from [Access](#access): upstream authentication sets the credentials the agent receives, while the auth strategy checks the identity of callers at the gateway.

Enable **Authenticate to the upstream service with AWS IAM (SigV4)** when the agent runs on [Amazon Bedrock AgentCore Runtime](https://aws.amazon.com/bedrock/agentcore/), which only accepts requests signed with AWS IAM.
{{site.ai_gateway}} then signs every request to the agent for the `bedrock-agentcore` service, including requests that aren't A2A operations.
When it's disabled, {{site.ai_gateway}} forwards the caller's request without credentials of its own.

Choose where the credentials come from:

<!-- vale off -->
{% table %}
columns:
  - title: Credentials
    key: credentials
  - title: Choose it when
    key: when
rows:
  - credentials: "Static IAM user credentials: **AWS access key ID** and **AWS secret access key**, with an optional **AWS session token**"
    when: "The data plane runs outside AWS. Store the secret in a vault instead of in plain text."
  - credentials: "No access key: {{site.ai_gateway}} detects the credentials from its environment"
    when: "The data plane runs in AWS and already has credentials, for example from an EC2 instance profile or environment variables."
  - credentials: "**Assume role ARN** and **Role session name**, on top of either source"
    when: "The agent is in another AWS account, or you want short-lived credentials scoped to the agent. Recommended for production."
{% endtable %}
<!-- vale on -->

Set **AWS region** if {{site.ai_gateway}} can't infer it from the environment, and **STS endpoint URL** to use a custom AWS STS endpoint when assuming a role.

#### Upstream TLS

**Upstream TLS**, in the section's **Advanced fields**, secures the connection between {{site.ai_gateway}} and the agent:

* **Client certificate:** An [AI Certificate](/ai-gateway/entities/ai-certificate/) that {{site.ai_gateway}} presents to the agent, for an agent that only accepts clients with a certificate ([mutual TLS](/ai-gateway/entities/ai-agent/#upstream-tls)).
* **CA certificates:** [AI CA Certificates](/ai-gateway/entities/ai-ca-certificate/) that {{site.ai_gateway}} uses to verify the agent's certificate, for an agent that serves a certificate signed by a private CA. Without them, {{site.ai_gateway}} uses its default trust store.

You can set either option on its own.
The certificates must exist on the same {{site.ai_gateway}}. To add them, click **Manage certificates**.
The agent's URL must use `https` when you set either option.

The following example configures the same settings with the {{site.ai_gateway}} API or kongctl, which reference the certificates by name:

{% entity_example %}
type: agent
data:
  display_name: Booking agent
  name: booking-agent
  type: a2a
  config:
    url: https://booking-agent.internal.example.com
    certificates:
      - booking-agent-client-cert
    ca_certificates:
      - internal-root-ca
    route:
      paths:
        - /booking-agent
{% endentity_example %}

#### Proxy settings

Use **Proxy settings**, in the section's **Advanced fields**, when the data plane can't reach the agent directly and must go through a forward proxy, for example a corporate egress proxy.
Set the HTTP or HTTPS proxy host and port, and the proxy credentials if the proxy requires them.
To store the proxy username or password in a vault instead of in plain text, use **Look up key in vault** in the field.
**No proxy** is optional. List hosts there only when the data plane can reach them directly and they should skip the proxy, for example `localhost` or an internal host name.

{:.warning}
> Proxy settings don't work with **Multiple targets**. Requests to an A2A agent fail with a `500` error, and requests to an HTTP agent go directly to the targets without the proxy. Use **Single URL** with a proxy.

### Route

The **Route** section defines which requests reach the agent.
Add one or more rules:

<!-- vale off -->
{% table %}
columns:
  - title: Rule
    key: rule
  - title: Choose it when
    key: when
rows:
  - rule: "**Base path**"
    when: "Several agents share one gateway host, and each agent gets its own path, like `/booking-agent`."
  - rule: "**Hostname**"
    when: "Each agent gets its own domain, like `booking-agent.example.com`."
  - rule: "**Header**"
    when: "Callers select the agent with a request header, for example to route to a version."
{% endtable %}
<!-- vale on -->

The defaults of the route's **Advanced fields** work for most agents.
Change them in these cases:

* **Methods:** Any method by default. Leave it empty for an A2A agent, since callers reach it with `POST`, and fetch its Agent Card with `GET`.
* **Strip path:** Enabled by default, so {{site.ai_gateway}} removes the base path before it sends the request to the agent. Disable it if the agent expects the full path.
* **Preserve host:** Enable it if the agent needs the `Host` header that the caller sent, instead of its own host name.
* **Request buffering** and **Response buffering:** Enabled by default. Disable them for faster streaming of large or chunked requests and responses.

The **Advanced fields** also include **Protocols**, **Regex priority**, **HTTPS redirect status code**, and **Tags**.
See [Routing configuration](/ai-gateway/entities/ai-agent/#routing-configuration).

### Access

The **Access** section defines who can call the agent.
Both of its options are optional, but without them any caller whose request matches the route can use the agent.

#### Auth strategy

An agent can use one [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/), which checks the identity of callers before their requests reach the agent. To create a strategy without leaving the form, open the **Auth strategy** dropdown menu and click **Add auth strategy**.

Choose the strategy type based on how callers authenticate:

<!-- vale off -->
{% table %}
columns:
  - title: Strategy type
    key: type
  - title: Choose it when
    key: when
  - title: Result
    key: result
rows:
  - type: "Key authentication, with [principal mapping](/ai-gateway/entities/ai-auth-strategy/#principal-mapping) enabled"
    when: "Callers should use [virtual keys](/ai-access-management/virtual-keys/)."
    result: "Users, [agent identities](/ai-access-management/agents/), and groups call the agent with their own key, and requests are attributed to them."
  - type: "OpenID Connect"
    when: "Callers already get tokens from your identity provider."
    result: "Callers send their identity provider's token."
{% endtable %}
<!-- vale on -->

#### Access control

Enable **Restrict access with an ACL** to limit which callers can reach the agent.
An ACL needs to know who the caller is, so use it with an auth strategy.

Choose **Allow** to grant access only to callers that match a rule, or **Deny** to block them.
Build rules with the **Builder**, or write a [CEL](https://cel.dev/) expression in **Raw expression**.
Rules can match:

* A principal or a principal group from {{site.identity}}, for example a specific agent identity or a team. Principal rules need an auth strategy that looks up callers in {{site.identity}}. Principal group rules require {{site.ai_gateway}} 2.3 or later.
* Consumer groups and authenticated groups, by name.
* A consumer.
* A custom CEL expression, for access that depends on attributes like metadata.

Rules other than group names are evaluated as CEL expressions, which require {{site.ai_gateway}} 2.2 or later.
See [CEL-based ACLs](/ai-gateway/entities/ai-agent/#cel-based-acls).

### After you create the agent

An agent's details show its configuration and usage.
From the agent's details, you can:

* See the requests the agent received in the last 7 days in the **Usage** tab.
* Copy a sample request from the **Connect** tab.
* From the **Actions** dropdown menu, select "Edit", "View declarative config", or "Delete".

To attach [AI Policies](/ai-gateway/entities/ai-policy/) to the agent, add their names to the agent's [`policies`](/ai-gateway/entities/ai-agent/#attach-ai-policies) field with the {{site.ai_gateway}} API or kongctl.

To stop routing traffic to an agent without deleting it, disable the agent's toggle in the agents list.
