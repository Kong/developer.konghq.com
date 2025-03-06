---
title: "Control plane outage management"
content_type: reference
layout: reference

products:
    - gateway

works_on:
   - on-prem

min_version:
    gateway: '3.4'

description: placeholder

related_resources:
  - text: placeholder
    url: /
---

{{site.base_gateway}} can be set up to support configuring new data planes in the event of a control plane outage. This document explains how data plane resilience works, who should use it, and additional considerations. This mode should be used only for situations that require adherence to strict high-availability SLAs.

OR!!!

Starting in version 3.2, {{site.base_gateway}} can be configured to support configuring new data planes in the event of a control plane outage. This feature works by designating one or more backup nodes and allowing it read/write access to a data store. This backup node will automatically push valid {{site.base_gateway}} configurations to the data store. In the event of a control plane outage when a new node is created, it will pull the latest {{site.base_gateway}} configuration from the data store, configure itself, and start proxying requests. 

This option is only recommended for customers who have to adhere to strict availability SLAs, because it requires a larger maintenance load.

## How data plane resilience works

When the cluster adds new data plane nodes, the control plane uses a configuration file to provision those nodes. If the control plane experiences an outage, the data plane can't be provisioned and it will silently fail until it can establish a connection with the control plane. 

If {{site.base_gateway}} is configured to manage adding new data plane nodes during a control plane outage, new nodes are configured by reading the configuration file that is located in the designated S3-compatible storage volume instead of silently failing.

By designating a dedicated backup node, any changes to the configuration file are pushed to the S3-compatible storage. Any new data plane nodes read the configuration file from the S3-compatible storage volume and consume the new configuration changes. 


## Data plane management during a control plane outage

When a control plane outage occurs, a new data plane node added to the cluster behaves like the following:  

1. The new data plane node determines that the control plane is unreachable. 
1. The new data plane node reads the configuration file from the S3-compatible storage volume, configures itself, caches the fetched configuration file, and begins proxying requests.
1. The new data plane node continuously tries to establish a connection with the control plane. 

The S3 compatible storage volume is only accessed when the data plane node is created. The configuration will never be pulled from the storage after creation. The data plane will fail if it depends on any other functionality from the control plane. 

{:.important}
> If the data plane and control plane are both configured to `export` a configuration, assuming that they are both configured with the right level of authentication, the data plane will write to the storage volume first, and then the control plane will overwrite the configuration. You should avoid this configuration.

{:.important}
> **Important:** Storage volume write access is only granted to the backup node.
> It is your responsibility to apply any encryption modules your storage provider recommends to encrypt the configuration in the storage volume. 


## Configure data plane resilience 

Data plane resilience is managed in the [`kong.conf`](/gateway/manage-kong-conf/) configuration file by the following parameters: 

```
cluster_fallback_config_import: on
cluster_fallback_config_storage: $STORAGE_ENDPOINT
cluster_fallback_config_export = off
```

The following table provides details about these parameters:

<!--vale off-->
{% kong_config_table %}
config:
  - name: cluster_fallback_config_import
    description: Fetches the fallback configuration from the URL passed in `cluster_fallback_config_storage` if the CP is unreachable. This should only be enabled on the data plane.
  - name: cluster_fallback_config_storage
  - name: cluster_fallback_config_export
    description: This parameter allows you to upload the configuration to the storage volume. This should only be enabled on the backup node.
{% endkong_config_table %}
<!--vale on-->

In addition, you'll also need to configure settings based on the S3-compatible storage type you're using.

### Amazon S3 storage

In this setup, you need to designate one backup node. 
The backup node must have read and write access to the S3 bucket, and the data plane nodes that are provisioned must have read access to the same S3 bucket.
The backup node is responsible for communicating the state of the {{site.base_gateway}} `kong.conf` configuration file from the control plane to the S3 bucket.

Nodes are initialized with fallback configs via environment variables, including `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION`. 
If associating with an IAM role and if the backup node does not reside on the AWS platform, an additional environment variable `AWS_SESSION_TOKEN` may be necessary. 


{:.important}
> We do not recommend using backup nodes to proxy traffic. The backup job enlarges the attack surface of a proxying DP and contributes significantly to the P99 delay. You need to know the risk if you want to deploy a node this way, 
{% if_version lte:3.5.x %} and a DP acting as a backup node cannot be provisioned with backup configurations.{% endif_version %}{% if_version gte:3.6.x %}and the DP needs to be at least `3.6.0.0` to be provisioned with backup configuration when it's configured as a backup node. 
Although a single backup node is sufficient for all deployments, you can also configure additional backup nodes. A leader election algorithm selects one node from the group of designated backup nodes to do the backup job.
{% endif_version %}

For more information about the data that is set in the environment variables, review the [AWS environment variable configuration documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html).

Using Docker Compose, you can configure the backup nodes:

```yaml
kong-exporter:
    image: 'kong/kong-gateway:latest'
    ports:
      - '8000:8000'
      - '8443:8443'
    environment:
      <<: *other-kong-envs
      AWS_REGION: 'us-east-2'
      AWS_ACCESS_KEY_ID: <access_key_write>
      AWS_SECRET_ACCESS_KEY: <secret_access_key_write>
      KONG_CLUSTER_FALLBACK_CONFIG_STORAGE: s3://test-bucket/test-prefix
      KONG_CLUSTER_FALLBACK_CONFIG_EXPORT: "on"

```

{% if_version lte:3.5.x %}
This node is responsible for writing to the S3 bucket when it receives new configuration. The file structure is automatically created inside of the bucket and should not be created manually. If the node version is `3.2.0.0`, using the example above, the key name will be `test-prefix/3.2.0.0/config.json`. 
{% endif_version %}

{% if_version gte:3.6.x %}
All the object keynames/prefixes mentioned in the following paragraphs are parameterized with the prefix given in the config and the gateway version. For example, let's say the node has a version of `3.6.0.0`.

The backup nodes will create registering files to run the leader election with a prefix `test-prefix/3.6.0.0/election/`. You can set up a lifecycle rule to delete objects with this prefix if it's not updated for days.

The selected node is responsible for writing to the S3 bucket when it receives new configuration. The file structure is automatically created inside of the bucket and should not be created manually. The key name is `test-prefix/3.6.0.0/config.json`.

{% endif_version %}

Both the control plane and data plane can be configured to export configurations.

You can configure new data planes to load a configuration from the S3 bucket if the control plane is unreachable using the following environment variables: 

```yaml
kong-dp-importer:
    image: 'kong/kong-gateway:latest'
    ports:
      - '8000:8000'
      - '8443:8443'
    environment:
      <<: *other-kong-envs
      AWS_REGION: 'us-east-2'
      AWS_ACCESS_KEY_ID: <access_key_read>
      AWS_SECRET_ACCESS_KEY: <secret_access_key_read>
      KONG_CLUSTER_FALLBACK_CONFIG_STORAGE: s3://test-bucket/test-prefix
      KONG_CLUSTER_FALLBACK_CONFIG_IMPORT: "on"

```

### Google Cloud storage

In this setup, you need to designate one backup node. 
The backup node must have read and write access to the GCP cloud storage bucket and the data plane nodes that are provisioned must have read access to the same GCP cloud storage bucket. 
This node is responsible for communicating the state of the {{site.base_gateway}} `kong.conf` configuration file from the control plane to the GCP cloud storage bucket.

Credentials are passed via the environment variable `GCP_SERVICE_ACCOUNT`. For more information about credentials review the [GCP credentials documentation](https://developers.google.com/workspace/guides/create-credentials).

A backup node should not be used to proxy traffic. A single backup node is sufficient for all deployments.

Using Docker Compose, you can configure the backup node:

```yaml
kong-dp-exporter:
    image: 'kong/kong-gateway:latest'
    ports:
      - '8000:8000'
      - '8443:8443'
    environment:
      <<: *other-kong-envs
      GCP_SERVICE_ACCOUNT: <GCP_JSON_STRING_WRITE>
      KONG_CLUSTER_FALLBACK_CONFIG_STORAGE: gcs://test-bucket/test-prefix
      KONG_CLUSTER_FALLBACK_CONFIG_EXPORT: "on"
```

This node is responsible for writing to the GCP bucket when it receives a new configuration. 
The file structure is automatically created inside of the bucket and should not be created manually. If the node version is `3.2.0.0`, using the example above, the key name will be `test-prefix/3.2.0.0/config.json`. 

Both the control plane and data plane can be configured to export configurations.


You can configure new data planes to load a configuration from the GCP cloud storage bucket if the control plane is unreachable using the following environment variables: 

```yaml
  kong-dp-importer:
    image: 'kong/kong-gateway:latest'
    ports:
      - '8000:8000'
      - '8443:8443'
    environment:
      <<: *other-kong-envs
      GCP_SERVICE_ACCOUNT: <GCP_JSON_STRING_READ>
      KONG_CLUSTER_FALLBACK_CONFIG_STORAGE: gcs://test-bucket/test-prefix
      KONG_CLUSTER_FALLBACK_CONFIG_IMPORT: "on"
```

### Other S3-compatible storage

Non-AWS S3 compatible object storage can be configured. The process is similar to the AWS S3 process, but requires an additional parameter `AWS_CONFIG_STORAGE_ENDPOINT`, which should be set to the endpoint of your object storage provider. 

The example below uses MinIO to demonstrate configuring a backup node: 

```yaml
  kong-exporter:
    image: 'kong/kong-gateway:latest'
    ports:
      - '8000:8000'
      - '8443:8443'
    environment:
      <<: *other-kong-envs
      AWS_REGION: 'us-east-2'
      AWS_ACCESS_KEY_ID: <access_key_write>
      AWS_SECRET_ACCESS_KEY: <secret_access_key_write>
      KONG_CLUSTER_FALLBACK_CONFIG_EXPORT: "on"
      KONG_CLUSTER_FALLBACK_CONFIG_STORAGE: s3://test-bucket/test-prefix
      AWS_CONFIG_STORAGE_ENDPOINT: http://minio:9000/
```