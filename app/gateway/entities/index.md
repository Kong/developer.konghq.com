---
title: Kong Gateway Entities
layout: landing_page
entities: 
 - service
 - route
 - upstream
 - plugin
related_resources:
  - text: How to create rate limiting tiers
    url: /plugins/rate-limiting/
---


## Entities

Kong entities refer to the various components and objects that make up the Kong API Gateway and its ecosystem. 

Entities include:

* [Services]: Represent your upstream APIs or microservices. Each Service corresponds to a set of APIs that you want to expose through Kong.
* Routes: Define how requests are mapped to Services. Routes specify criteria such as paths, hosts, methods, and headers that determine which Service a request should be proxied to.
* Consumers: Represent the clients or users consuming your APIs. Consumers can be individual users, applications, or other services.
* Plugins: Extend Kong’s functionality by adding features such as authentication, rate limiting, logging, and transformations. Plugins can be applied globally or on specific Services, Routes, or Consumers.
* Certificates: Used for securing communication between clients and Kong or between Kong and upstream services using SSL/TLS.
* Upstreams: Represent a load-balanced group of backend services. An Upstream can have multiple Targets (backend services), and Kong will distribute requests among these Targets.
* Targets: The actual backend servers or instances that Kong forwards requests to. They are part of an Upstream.
* SNIs: Server Name Indications used to support multiple SSL certificates for different domain names using a single IP address.
* ACLs (Access Control Lists): Used to control access to Services and Routes by grouping Consumers and allowing or denying access based on these groups.
* Certificates: Used to handle SSL/TLS certificates for secure communication.


{place holder text about how kong entities are kong gateway entities that map across all of our products.}


![image](https://raw.githubusercontent.com/Kong/docs.konghq.com/main/app/assets/images/products/konnect/getting-started/konnect-gateway-entities.png) #this thing renders to the right 

