---
title: Create a Cloud Gateway Data Plane group configuration
description: "Provision a Dedicated Cloud Gateway Data Plane group configuration in {{site.konnect_short_name}} using the `KonnectCloudGatewayDataPlaneGroupConfiguration` CRD."
content_type: how_to

permalink: /operator/konnect/crd/cloud-gateways/configuration/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: "Konnect CRDs: Cloud Gateways"

products:
  - operator

works_on:
  - konnect

entities: []
search_aliases:
  - kgo data plane group
  - kgo cloud gateway configuration
tags:
  - konnect-crd
related_resources:
  - text: Dedicated Cloud Gateway
    url: /dedicated-cloud-gateways/
tldr:
  q: How do I configure a Dedicated Cloud Gateway with Data Plane groups in {{site.konnect_short_name}}?
  a: Use the `KonnectCloudGatewayDataPlaneGroupConfiguration` resource to define autoscaling Data Plane groups and associate them with Cloud Gateway networks.


prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true
      network: true

cleanup:
  inline:
    - title: Delete the resources created in this guide
      content: |
        Deleting the `KonnectCloudGatewayDataPlaneGroupConfiguration` removes the Data Plane group from {{ site.konnect_short_name }}. Deleting the `KonnectGatewayControlPlane` also deletes the control plane {{ site.operator_product_name }} created in {{ site.konnect_short_name }}:

        ```bash
        kubectl delete -n kong --ignore-not-found \
          konnectcloudgatewaydataplanegroupconfiguration/konnect-cg-dpconf \
          konnectcloudgatewaynetwork/konnect-network-1 \
          konnectgatewaycontrolplane/gateway-control-plane \
          konnectapiauthconfiguration/konnect-api-auth
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/kubernetes.svg

    - title: Delete the namespaces
      content: |
        ```bash
        helm uninstall kong-operator -n kong-system
        kubectl delete namespace kong kong-system
        ```
      icon_url: /assets/icons/kubernetes.svg

automated_tests: false
---

## Create a `KonnectCloudGatewayDataPlaneGroupConfiguration`

Use the `KonnectCloudGatewayDataPlaneGroupConfiguration` resource to configure data plane groups for a Dedicated Cloud Gateway. Only one configuration can exist per Control Plane.

Creating multiple configurations will result in overwriting the previous one. Each Dedicated Cloud Gateway supports only a single `DataPlaneGroupConfiguration`.

<!-- vale off -->
{% konnect_crd %}
apiVersion: konnect.konghq.com/v1alpha1
kind: KonnectCloudGatewayDataPlaneGroupConfiguration
metadata:
  name: konnect-cg-dpconf
spec:
  api_access: private+public
  version: "3.10"
  dataplane_groups:
    - provider: aws
      region: eu-west-1
      networkRef:
        type: namespacedRef
        namespacedRef:
          name: konnect-network-1
      autoscale:
        type: autopilot
        autopilot:
          base_rps: 100          
      environment:
        - name: KONG_LOG_LEVEL
          value: debug
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->


Since creating a Data Plane Group Configuration can take some time, you can monitor its status by checking the `dataplane_groups` field. Data Plane Group Configurations receive this field when they are successfully provisioned in Konnect.

<!-- vale off -->
{% validation custom-command %}
command: |
  kubectl get -n kong konnectcloudgatewaydataplanegroupconfiguration.konnect.konghq.com konnect-cg-dpconf -o=jsonpath='{.status.dataplane_groups}' | yq -p json
expected:
  return_code: 0
  message: eu-west-1
render_output: false
{% endvalidation %}
<!-- vale on -->

## Validation


{% validation kubernetes-resource %}
kind: KonnectCloudGatewayDataPlaneGroupConfiguration
name: konnect-cg-dpconf
{% endvalidation %}
