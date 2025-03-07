---
title: "Control Plane outage management"
content_type: reference
layout: reference

products:
    - gateway

works_on:
   - on-prem

tags:
    - control-plane
    - data-plane
    - resilience

min_version:
    gateway: '3.4'

description: Configure Data Plane resilience in case of a Control Plane outage.

related_resources:
  - text: "{{site.konnect_short_name}} Data Plane nodes"
    url: /gateway-manager/data-plane-nodes/
  - text: "{{site.base_gateway}} Control Plane and Data Plane communication"
    url: /gateway/cp-dp-communication/
---

{{site.base_gateway}} can be set up to support configuring new Data Planes in the event of a Control Plane outage. Data Plane resilience works by designating one or more backup nodes and allowing it read/write access to a data store. This backup node will automatically push valid {{site.base_gateway}} configurations to the data store. In the event of a Control Plane outage, when a new node is created, it will pull the latest {{site.base_gateway}} configuration from the data store, configure itself, and start proxying requests. 

{:.info}
>This option is only recommended for users who have to adhere to strict high-availability SLAs because it requires a larger maintenance load.

## How Data Plane resilience works

When the cluster adds new Data Plane nodes, the nodes are configured by the Control Plane using a configuration file. 

If the Control Plane experiences an outage, the Data Plane can't be provisioned and it will silently fail until it can establish a connection with the Control Plane. 

When a Control Plane outage occurs, a new Data Plane node added to the cluster behaves like the following:  

1. The new Data Plane node determines that the Control Plane is unreachable. 
1. The new Data Plane node reads the configuration file from the S3-compatible storage volume, configures itself, caches the fetched configuration file, and begins proxying requests.
1. The new Data Plane node continuously tries to establish a connection with the Control Plane. 

The S3 compatible storage volume is only accessed when the Data Plane node is created. The configuration will never be pulled from the storage after creation. The Data Plane will fail if it depends on any other functionality from the Control Plane. 

{:.warning}
> **Important:** Storage volume write access is only granted to the backup node. It is your responsibility to apply any encryption modules your storage provider recommends to encrypt the configuration in the storage volume. 

## Configure Data Plane resilience 

Data Plane resilience is managed by [`kong.conf`](/gateway/manage-kong-conf/) with the following parameters: 

```
cluster_fallback_config_import: on
cluster_fallback_config_storage: $STORAGE_ENDPOINT
cluster_fallback_config_export = off
```

Avoid configuring both the Data Plane and Control Plane to `export` a configuration. Assuming that they are both configured with the correct level of authentication, the Data Plane will write to the storage volume first, and then the Control Plane will overwrite the configuration.

The following table provides details about these parameters:

<!--vale off-->
{% kong_config_table %}
config:
  - name: cluster_fallback_config_import
    description: Fetches the fallback configuration from the URL passed in `cluster_fallback_config_storage` if the CP is unreachable. This should only be enabled on the Data Plane.
  - name: cluster_fallback_config_storage
  - name: cluster_fallback_config_export
    description: This parameter allows you to upload the configuration to the storage volume. This should only be enabled on the backup node.
{% endkong_config_table %}
<!--vale on-->

In addition, you'll also need to configure settings based on the S3-compatible storage type you're using.

## Amazon S3 storage

In this setup, you need to designate one backup node. 
The backup node must have read and write access to the S3 bucket, and the Data Plane nodes that are provisioned must have read access to the same S3 bucket.
The backup node is responsible for communicating the state of the {{site.base_gateway}} `kong.conf` configuration file from the Control Plane to the S3 bucket.

Nodes are initialized with fallback configs via environment variables, including `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION`. 
If you're associating this with an IAM role and if the backup node doesn't reside on the AWS platform, you may also need to use the `AWS_SESSION_TOKEN` environment variable. 


{:.warning}
> We don't recommend using backup nodes to proxy traffic. The backup job enlarges the attack surface of a proxying Data Plane and contributes significantly to the P99 delay. You need to know the risk if you want to deploy a node this way, 
{% if_version lte:3.5.x %} and a Data Plane acting as a backup node cannot be provisioned with backup configurations.{% endif_version %}{% if_version gte:3.6.x %}and the Data Plane needs to be at least `3.6.0.0` to be provisioned with backup configuration when it's configured as a backup node. 
Although a single backup node is sufficient for all deployments, you can also configure additional backup nodes. A leader election algorithm selects one node from the group of designated backup nodes to do the backup job.
{% endif_version %}

For more information about the data that is set in the environment variables, see the [AWS environment variable configuration documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html).

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

The selected node is responsible for writing to the S3 bucket when it receives new configuration. The file structure is automatically created inside of the bucket and shouldn't be created manually. The key name is `test-prefix/3.6.0.0/config.json`.

{% endif_version %}

Both the Control Plane and Data Plane can be configured to export configurations.

You can configure new Data Planes to load a configuration from the S3 bucket if the Control Plane is unreachable using the following environment variables: 

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

## Google Cloud storage

In this setup, you need to designate one backup node. 
The backup node must have read and write access to the GCP cloud storage bucket and the provisioned Data Plane nodes must have read access to the same GCP cloud storage bucket. 
This node is responsible for communicating the state of the {{site.base_gateway}} `kong.conf` configuration file from the Control Plane to the GCP cloud storage bucket.

Credentials are passed via the `GCP_SERVICE_ACCOUNT` environment variable . For more information about credentials, see the [GCP credentials documentation](https://developers.google.com/workspace/guides/create-credentials).

A backup node shouldn't be used to proxy traffic. A single backup node is sufficient for all deployments.

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

Both the Control Plane and Data Plane can be configured to export configurations.


You can configure new Data Planes to load a configuration from the GCP cloud storage bucket if the Control Plane is unreachable using the following environment variables: 

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

## Other S3-compatible storage

You can configure non-AWS S3-compatible object storage. The process is similar to the AWS S3 process, but requires an additional parameter: `AWS_CONFIG_STORAGE_ENDPOINT`. This is set to the endpoint of your object storage provider. 

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