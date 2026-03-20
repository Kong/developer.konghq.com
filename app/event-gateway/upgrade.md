---
title: "Upgrading {{site.event_gateway_short}}"

description: "This guide walks you through upgrading {{site.event_gateway}} control planes and data planes."

content_type: reference
layout: reference

products:
  - event-gateway

related_resources:
  - text: "{{site.event_gateway_short}} breaking changes and known issues"
    url: /event-gateway/breaking-changes/
  - text: "{{site.event_gateway_short}} version support"
    url: /event-gateway/version-support-policy/
  - text: "{{site.event_gateway_short}} changelog"
    url: /event-gateway/changelog/

breadcrumbs:
  - /event-gateway/

works_on:
  - konnect

faqs:
  - q: Why isn’t the control plane (CP) minimum version automatically inferred from data plane (DP) versions?
    a: |
      Setting the minimum version manually lets you make a conscious choice about the data plane versions you want to run. 
      This way, you can intentionally run mixed-version fleets during upgrades, staging, or blue-green rollouts.

      This setting also prevents you from accidentally configuring features that the data planes nodes don't support.

  - q: Will `latest` be supported as a minimum supported data plane version?
    a: |
      No. The minimum supported DP version will always be a specific version, not `latest`.

  - q: What happens if I enable a gated field through the {{site.event_gateway_short}} API instead of the UI?
    a: |
      If your configured minimum version doesn't support the field, the API validation will reject the request with an error.

  - q: Can I run multiple data plane versions at the same time?
    a: |
      Yes. However, the control plane can only generate configuration for DP nodes at or above the configured minimum DP version.
      If older nodes connect to the control plane, they will be marked incompatible and will not receive any configuration.

      For example, if you have minimum version set to 1.1:
      * The control plane will connect to data planes running 1.1.0 and newer versions.
      * The control plane will ignore data planes running 1.0 versions, and they will not receive any configuration updates.
    
  - q: How do I downgrade my control plane version?
    a: |
      The minimum control plane version can be downgraded with the help of [Kong Support](https://support.konhq.com).
  - q: When should I change the minimum runtime version
    a: |
       If you don't need to use features that exist on newer versions you don't need to update the minimum runtime version. However, it's recommended to update this version once all your dataplanes have been upgraded and things are stable.

---

To upgrade to a new {{site.event_gateway_short}} version, choose one of the following paths:

* **Upgrade both the control plane and data planes**: Recommended. This gives you access to all new features.
* **Upgrade only the data planes**: This allows you to take advantage of data plane improvements but doesn't let you access any new configurations.

### Prerequisites

* Review [{{site.event_gateway_short}} release notes](/event-gateway/changelogs/)
* Review [{{site.event_gateway_short}} breaking changes](/event-gateway/breaking-changes/)

### 1. Upgrade data planes

1. In the {{site.konnect_short_name}} sidebar, navigate to [**{{site.event_gateway_short}}**](https://cloud.konghq.com/event-gateway/).
1. Click a control plane.
1. In the {{site.event_gateway_short}} sidebar, click **Data Plane Nodes**.
1. Provision a data plane node running the new version.

    Confirm the new node appears in the list, shows a _Connected_ status, and was last seen _Just Now_.

1. Repeat for each node you need to replace.
1. When the new nodes are connected and functioning, disconnect and shut down the old nodes.

    {:.info}
    > You can't shut down data plane nodes from the {{site.konnect_short_name}} UI. 
    Old nodes will also remain listed as `Connected` for a few hours after they have been removed or shut down.

1. Verify traffic flows through the new node by accessing a virtual cluster configured on the control plane.

    For example:

    ```sh
    kafkactl -C kafkactl.yaml --context my-vc list topics
    ```

### 2. Upgrade control plane

1. In the {{site.konnect_short_name}} sidebar, navigate to [**{{site.event_gateway_short}}**](https://cloud.konghq.com/event-gateway/).
1. Click the control plane you want to upgrade.
1. From the **Actions** dropdown menu, select **Edit {{site.event_gateway_short}}**.
1. Set **Minimum supported data plane version** to the version you want to use.

   {:.warning}
   > This change cannot be reverted manually. Confirm you want to upgrade before saving.

1. Click **Save**.

At this point, you will have access to all of the new features on the control plane. Your data planes will behave as follows:
* Any data planes running the new version or above will receive new control plane configurations.
* Any remaining data planes below the new minimum control plane version will continue to appear as `Connected` but will no longer receive configuration and will show an incompatibility warning.