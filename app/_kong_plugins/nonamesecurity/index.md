---
title: 'Noname Security Kong Traffic Source'
name: 'Noname Security Kong Traffic Source'

content_type: plugin

publisher: noname-security
description: "Noname Security machine learning & prevention blocking for {{site.base_gateway}} discovery"

products:
    - gateway

works_on:
    - on-prem
    - konnect

third_party: true

support_url: https://success.nonamesecurity.com/

icon: nonamesecurity.png

search_aliases:
  - nonamesecurity-kongtrafficsource

related_resources:
  - text: Performance benchmark of {{site.base_gateway}} with Noname Security
    url: https://docs.nonamesecurity.com/docs/kong-performance-results

min_version:
  gateway: '1.0'
---

The Noname Traffic Source plugin (also known as `nonamesecurity`) lets you tune
how the Noname machine learning engine receives {{site.base_gateway}} API traffic data to inspect.

## How it works

All Noname integrations require you to create an integration profile in Noname. 
Nearly all integrations require you to have administration access to the systems you want to integrate. 
The simplest integrations require you to record some kind of credentials or access key from the remote system to enter into Noname while creating the profile. 
This enables Noname to receive information from, or perform actions on, the remote system. 
For example, an action could be fetching a log file, or initiating a block based on an incident created in Noname.

Prevention is enabled by default. To disable the prevention feature, review the [Noname documentation](https://docs.nonamesecurity.com/docs/kong-plugin#disabling-the-prevention-feature).

If you already had a prevention integration configured and would like to migrate to this new integration, see the [upgrade guide in the Noname documentation](https://docs.nonamesecurity.com/docs/kong-plugin#updating-your-prevention-integration).

## Install

The Noname Security Kong plugin is available as a LuaRocks module.

The [Noname Security install and configuration documentation](https://docs.nonamesecurity.com/docs/kong-plugin) explains how set up a custom Docker image with the plugin preinstalled, using the Noname admin user interface. 

Alternatively, use the following steps to manually set up the integration.

### Create the integration profile

Configure the integration profile in Noname and download the plugin:

1. In the Noname UI, navigate to **Settings** > **Integrations** > **Traffic Sources**. 
2. Select **Add Integration** and select the Kong tile to create an integration profile. 
3. Download the Zip file, and copy it to your Kong machine, then select **Next**. 
4. Provide an alias for the integration.
5. Select **Finish** to save the integration.

### Install the Noname Security plugin

Choose your installation method:

{% navtabs "install-noname" %}
{% navtab "Luarocks" %}

{% capture step_one %}
1. In your Kong machine CLI shell, navigate to the location of the copied zip file and unzip the file.
{% endcapture %}

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="nonamesecurity.rockspec" first-step=step_one %}

{% endnavtab %}
{% navtab "Docker" %}

If you are using Docker, see the following example Dockerfile for 
installing the Noname Security plugin:

```docker
FROM kong/kong-gateway:latest

USER root

RUN \apt-get update && \apt-get install unzip -y

WORKDIR /usr/kong/noname

RUN apt update && apt-get install -y build-essential git curl unzip

RUN bash -c 'mkdir -pv {nonamesecurity}'

COPY ./noname-security-kong-policy.zip nonamesecurity/noname-security-kong-policy.zip

RUN unzip nonamesecurity/noname-security-kong-policy.zip -d nonamesecurity && rm nonamesecurity/noname-security-kong-policy.zip

RUN cd nonamesecurity && luarocks make

USER kong
```
{% endnavtab %}
{% endnavtabs %}