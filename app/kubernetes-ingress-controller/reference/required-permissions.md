---
title: Permissions required to install {{ site.kic_product_name }}

description: |
  Learn about the permissions required to install and run {{site.kic_product_name}}.

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Reference

content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect
---

To install {{ site.kic_product_name }}, you need to have the permissions to **write** (create, update, get, list, watch in Kubernetes's RBAC model) the following resources:

* `CustomResourceDefinition` to configure Kong-specific entities (for example, `KongPlugin` to configure plugins).

* `ClusterRole`, `ClusterRoleBinding` (cluster scoped), `Role`,`RoleBinding` (namespace scoped) to create RBAC rules to enable {{ site.kic_product_name }} to access required resources.

* `Deployment`, `Service`, `ServiceAccount`, `Secret`, and `ConfigMap` to create deployments, services, and to specify their configurations. 

* `IngressClass` to install an ingress class managed by {{ site.kic_product_name }}.

* `ValidatingWebhookConfiguration` to create a webhook to validate managed resources.

* (Optional) `HorizontalPodAutoscaler` to enable autoscaling.

* (Optional) `PersistentVolumeClaim` to set volumes used for the database, and `Job` to run migration jobs if you're using a [database-backed](/kubernetes-ingress-controller/deployment-topologies/db-backed/) deployment.


## All required resources

You need write access to the following resources to install {{ site.kic_product_name }}:

<!--vale off-->
{% table %}
columns:
  - title: Resource Kind
    key: kind
  - title: Resource APIVersion
    key: apiVersion
  - title: Resource Scope
    key: scope
  - title: Purpose
    key: usage
rows:
  - kind: "`CustomResourceDefinition`"
    apiVersion: "`apiextensions.k8s.io/v1`"
    scope: Cluster
    usage: Install CRDs

  - kind: "`ClusterRole`"
    apiVersion: "`rbac.authorization.k8s.io/v1`"
    scope: Cluster
    usage: Install RBAC rules

  - kind: "`ClusterRoleBinding`"
    apiVersion: "`rbac.authorization.k8s.io/v1`"
    scope: Cluster
    usage: Install RBAC rules

  - kind: "`Role`"
    apiVersion: "`rbac.authorization.k8s.io/v1`"
    scope: Namespaced
    usage: Install RBAC rules

  - kind: "`RoleBinding`"
    apiVersion: "`rbac.authorization.k8s.io/v1`"
    scope: Namespaced
    usage: Install RBAC rules

  - kind: "`Deployment`"
    apiVersion: "`apps/v1`"
    scope: Namespaced
    usage: Install components

  - kind: "`Service`"
    apiVersion: "`v1`"
    scope: Namespaced
    usage: Install components

  - kind: "`ServiceAccount`"
    apiVersion: "`v1`"
    scope: Namespaced
    usage: Install components

  - kind: "`Secret`"
    apiVersion: "`v1`"
    scope: Namespaced
    usage: Set configurations and credentials

  - kind: "`ConfigMap`"
    apiVersion: "`v1`"
    scope: Namespaced
    usage: Set configurations

  - kind: "`IngressClass`"
    apiVersion: "`networking.k8s.io/v1`"
    scope: Cluster
    usage: Install ingress class

  - kind: "`ValidatingWebhookConfiguration`"
    apiVersion: "`admissionregistration.k8s.io/v1`"
    scope: Cluster
    usage: Configure validating webhooks{% endtable %}
<!--vale on-->

### Optional resources

The following resources may be required for specific use cases:

<!--vale off-->
{% table %}
columns:
  - title: Resource Kind
    key: kind
  - title: Resource APIVersion
    key: apiVersion
  - title: Resource Scope
    key: scope
  - title: Purpose
    key: usage
rows:
  - kind: "`PersistentVolumeClaim`"
    apiVersion: "`v1`"
    scope: Namespaced
    usage: Claim volume for DB

  - kind: "`Job`"
    apiVersion: "`v1`"
    scope: Namespaced
    usage: Create DB migration jobs

  - kind: "`HorizontalPodAutoscaler`"
    apiVersion: "`autoscaling/v2`"
    scope: Namespaced
    usage: configure autoscaling{% endtable %}
<!--vale on-->
