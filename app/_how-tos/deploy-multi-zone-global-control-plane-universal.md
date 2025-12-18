---
title: Deploy a multi-zone global {{site.mesh_product_name}} control plane in Universal mode
description: TODO
content_type: how_to
permalink: /mesh/deploy-multi-zone-global-control-plane-universal/
bread-crumbs: 
  - /mesh/
related_resources:
  - text: "{{site.mesh_product_name}}"
    url: /mesh/

products:
  - mesh

tldr:
  q: TODO
  a: TODO
        
---

## Create network

```sh
docker network create kong-mesh-system
```
 
## Create database

```sh
docker run -d --network kong-mesh-system --name postgres -p 5432:5432 -e POSTGRES_USER=kong -e POSTGRES_PASSWORD=pass123 postgres
```

```sh
docker exec -it postgres psql -h localhost -U kong
```

```sh
CREATE DATABASE kmesh;
```

## Create global control plane

```sh
docker run \
    -e KUMA_MODE=global \
    -e KUMA_ENVIRONMENT=universal \
    -e KUMA_STORE_TYPE=postgres \
    -e KUMA_STORE_POSTGRES_HOST=postgres \
    -e KUMA_STORE_POSTGRES_PORT=5432 \
    -e KUMA_STORE_POSTGRES_USER=kong \
    -e KUMA_STORE_POSTGRES_PASSWORD=pass123 \
    -e KUMA_STORE_POSTGRES_DB_NAME=kmesh \
    --network kong-mesh-system \
  kumahq/kuma-cp:2.12.5 migrate up
```

## Create zone control plane

```sh
docker run \
 -e KUMA_MODE=zone \
 -e KUMA_MULTIZONE_ZONE_NAME=zone-1\
 -e KUMA_ENVIRONMENT=universal \
 -e KUMA_STORE_TYPE=postgres \
 -e KUMA_STORE_POSTGRES_HOST=postgres \
 -e KUMA_STORE_POSTGRES_PORT=5432 \
 -e KUMA_STORE_POSTGRES_USER=kong \
 -e KUMA_STORE_POSTGRES_PASSWORD=pass123 \
 -e KUMA_STORE_POSTGRES_DB_NAME=kmesh \
 -e KUMA_MULTIZONE_ZONE_GLOBAL_ADDRESS=grpcs://localhost:5685 \
 --network kong-mesh-system \
 kumahq/kuma-cp:2.12.5 run
```

## TODO

```sh
kumactl config control-planes add \
  --address http://localhost:5681 \
  --name "zone-1-cp" \
  --overwrite
```

```sh
kumactl generate zone-token --zone=zone-1 --scope egress --scope ingress > /tmp/zone-token
```

```sh
echo "type: ZoneIngress
name: ingress-01
networking:
  address: 127.0.0.1
  port: 10000
  advertisedAddress: 10.0.0.1
  advertisedPort: 10000" > ingress-dp.yaml
```

```sh
kuma-dp run \
  --proxy-type=ingress \
  --cp-address=https://localhost:5678 \
  --dataplane-token-file=/tmp/zone-token \
  --dataplane-file=ingress-dp.yaml
```

```sh
echo "type: ZoneEgress
name: zoneegress-01
networking:
  address: 127.0.0.1
  port: 10002" > zoneegress-dataplane.yaml
```

```sh
 kuma-dp run \
   --proxy-type=egress \
   --cp-address=https://localhost:5678 \
   --dataplane-token-file=/tmp/zone-token \
   --dataplane-file=zoneegress-dataplane.yaml
```

```sh
# forward traffic from local pc into global control plane in the cluster
kubectl -n kuma-system port-forward svc/kuma-control-plane 5681:5681 &

# configure control plane for kumactl
kumactl config control-planes add \
  --name global-control-plane \
  --address http://localhost:5681 \
  --skip-verify
```
