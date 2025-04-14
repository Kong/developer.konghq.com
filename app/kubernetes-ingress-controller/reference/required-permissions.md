---
title: Permissions required to install {{ site.kic_product_name }}

description: |
  What permissions are required to install {{site.kic_product_name}} if I'm not a super admin of the cluster? What permissions are required to run {{site.kic_product_name}}?

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
  - kind: CustomResourceDefinition
    apiVersion: apiextensions.k8s.io/v1
    scope: cluster
    usage: install CRDs

  - kind: ClusterRole
    apiVersion: rbac.authorization.k8s.io/v1
    scope: cluster
    usage: install RBAC rules

  - kind: ClusterRoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    scope: cluster
    usage: install RBAC rules

  - kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    scope: namespaced
    usage: install RBAC rules

  - kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    scope: namespaced
    usage: install RBAC rules

  - kind: Deployment
    apiVersion: apps/v1
    scope: namespaced
    usage: install components

  - kind: Service
    apiVersion: v1
    scope: namespaced
    usage: install components

  - kind: ServiceAccount
    apiVersion: v1
    scope: namespaced
    usage: install components

  - kind: Secret
    apiVersion: v1
    scope: namespaced
    usage: set configurations and credentials

  - kind: ConfigMap
    apiVersion: v1
    scope: namespaced
    usage: set configurations

  - kind: IngressClass
    apiVersion: networking.k8s.io/v1
    scope: cluster
    usage: install ingress class

  - kind: ValidatingWebhookConfiguration
    apiVersion: admissionregistration.k8s.io/v1
    scope: cluster
    usage: configure validating webhooks
{% endtable %}

### Optional resources

The following resources may be required for specific use cases:

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
  - kind: PersistentVolumeClaim
    apiVersion: v1
    scope: namespaced
    usage: claim volume for DB

  - kind: Job
    apiVersion: v1
    scope: namespaced
    usage: create DB migration jobs

  - kind: HorizontalPodAutoscaler
    apiVersion: autoscaling/v2
    scope: namespaced
    usage: configure autoscaling
{% endtable %}
