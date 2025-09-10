---
title: "Reconciliation loop"
description: "How does the {{ site.gateway_operator_product_name }} reconciliation loop work?"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Key Concepts

faqs:
  - q: How often does the reconcile loop run?
    a: |
      New resources are created immediately using the {{ site.konnect_short_name }} API.

      Existing resources are processed once per minute by default. This is customizable, but we recommend keeping the default value so that you do not hit the {{ site.konnect_short_name }} API rate limit.

  - q: I deleted a resource in the UI, but it wasn’t recreated by the operator. Why?
    a: The reconciliation loop runs every 60 seconds. Wait one minute, then refresh the UI to see the resource restored.



---

{{site.gateway_operator_product_name}} continuously watches your Kubernetes cluster and reconciles its state with {{site.konnect_short_name}}.

This happens in a loop where the operator detects changes in the cluster and synchronizes them to {{site.konnect_short_name}}. Changes made in the Kubernetes cluster are propagated immediately. Changes made outside the cluster are overwritten within 60 seconds.

## How it works

The reconciliation loop follows these steps:


* On Kubernetes resource creation:
  - The operator checks if it has references and whether they are valid, if not it assigns a failure condition to the resource.
  - If the resource has references and they are valid, the operator calls the {{ site.konnect_short_name }} API's create method.
    - If the creation was unsuccessful, the operator assigns a failure condition to the resource.
    - If the creation was successful, the operator assigns the resource's `ID`, `OrgID`, `ServerURL` and status conditions.
  - The operator enqueues the resource for update after the configured sync period passes.

- When a Kubernetes resource is updated:
  - The operator checks if the resource's spec, annotations or labels have changed.
  - If the spec, annotations or labels have changed:
    - The operator calls the {{ site.konnect_short_name }} API's update method.
      - If the update was unsuccessful, the operator assigns a failure condition to the resource.
      - If the update was successful, the operator waits for the configured sync period to pass.
  - If the spec, annotations or labels have not changed:
    - If sync period has not passed, the operator enqueues the resource for update.
    - If sync period has passed, the operator calls the {{ site.konnect_short_name }} API's update method.
      - If the update was unsuccessful, the operator assigns a failure condition to the resource.
      - If the update was successful, the operator enqueues the resource for update.

- When a Kubernetes resource is deleted:
  - The operator calls the {{ site.konnect_short_name }} API's delete method.
    - If the deletion was unsuccessful, the operator assigns a failure condition to the resource.
    - If the deletion was successful, the operator removes the resource from the cluster.

This diagram illustrates the flow:

<!--vale off-->
{% mermaid %}
flowchart TB

    k8sResourceCreated(Kubernetes resource created)
    k8sResourceUpdated(Kubernetes resource updated)
    rLoopStart[Operator reconciliation start]
    failure[Assign object's status conditions to indicate failure]
    resourceSpecChanged{Resource spec, 
    annotations or 
    labels changed?}
    waitForSync["Wait until sync period passes (default 1m)
    (Prevent API rate limiting)"]
    createSuccess[Assign object's ID, OrgID, ServerURL and status conditions]
    hasReferences{If object has 
    references, 
    are they all valid?}
    isAlreadyCreated{Object 
    already created?}
    syncPeriodPassed[Sync period passed]
    updateKonnectEntity[Call Konnect API's update]
    wasUpdateSuccessful{Was update 
    successful?}
    wasCreateSuccessful{Was create 
    successful?}
    callCreate[Call Konnect API's create]

    k8sResourceCreated --> rLoopStart
    rLoopStart --> isAlreadyCreated
    isAlreadyCreated -->|Yes| waitForSync
    isAlreadyCreated -->|No| hasReferences
    hasReferences -->|Yes| callCreate
    hasReferences -->|No| failure
    callCreate --> wasCreateSuccessful
    wasCreateSuccessful -->|Yes| createSuccess
    wasCreateSuccessful -->|No| failure
    k8sResourceUpdated --> resourceSpecChanged
    resourceSpecChanged -->|Yes| updateKonnectEntity
    resourceSpecChanged -->|No| waitForSync
    createSuccess --> waitForSync
    waitForSync --> syncPeriodPassed
    syncPeriodPassed --> updateKonnectEntity
    updateKonnectEntity --> wasUpdateSuccessful
    wasUpdateSuccessful -->|Yes| waitForSync
    wasUpdateSuccessful -->|No| failure
    failure -->rLoopStart

{% endmermaid %}
<!--vale on-->
