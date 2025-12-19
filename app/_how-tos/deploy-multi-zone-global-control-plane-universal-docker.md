---
title: Deploy a multi-zone global {{site.mesh_product_name}} control plane in Universal mode with Docker
description: TODO
content_type: how_to
permalink: /mesh/deploy-multi-zone-global-control-plane-universal-docker/
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
```sh
exit
```

## Create global control plane

```sh
docker run \
    -e KUMA_STORE_TYPE=postgres \
    -e KUMA_STORE_POSTGRES_HOST=postgres \
    -e KUMA_STORE_POSTGRES_PORT=5432 \
    -e KUMA_STORE_POSTGRES_USER=kong \
    -e KUMA_STORE_POSTGRES_PASSWORD=pass123 \
    -e KUMA_STORE_POSTGRES_DB_NAME=kmesh \
    --network kong-mesh-system \
  kumahq/kuma-cp:2.12.5 migrate up
```


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
    -p 5681:5681 \
    -p 5685:5685 \
    --network kong-mesh-system \
    --name kong-mesh-global \
  kumahq/kuma-cp:2.12.5 run
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
 -e KUMA_MULTIZONE_ZONE_GLOBAL_ADDRESS=grpcs://kong-mesh-global:5685 \
 -e KUMA_MULTIZONE_ZONE_KDS_TLS_SKIP_VERIFY=true \
 --network kong-mesh-system \
 --name kong-mesh-zone-1 \
 -p 25681:5681 \
 -p 25678:5678 \
 kumahq/kuma-cp:2.12.5 run
```

## Configure kumactl

```sh
TOKEN=$(docker exec -it kong-mesh-zone-1 wget -q -O - http://localhost:5681/global-secrets/admin-user-token | jq -r .data | base64 -d)
```

```sh
export PATH=$(pwd)/kuma-2.12.5/bin:$PATH
```

```sh
kumactl config control-planes add \
 --name zone-1 \
 --address http://localhost:25681 \
 --auth-type=tokens \
 --auth-conf token=$TOKEN \
 --skip-verify \
 --overwrite
```

```sh
DP_TOKEN=$(kumactl generate zone-token --zone=zone-1 --valid-for 24h --scope egress --scope ingress)
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

## TODO

```sh
docker run \
  --network kong-mesh-system \
  -v /tmp/zone-token:/tmp/zone-token \
  -v /ingress-dp.yaml:/ingress-dp.yaml \
  -e TOKEN \
  kumahq/kuma-dp:2.12.5 run \
  --proxy-type=ingress \
  --cp-address=http://kong-mesh-zone-1:25678 \
  --name=ingress-01 \
  --dataplane-token=$TOKEN \
  --dataplane-file=ingress-dp.yaml
```

```sh
export PATH=$(pwd)/kuma-2.12.5/bin:$PATH
```

```sh
kumactl config control-planes add \
  --name global-control-plane \
  --address http://localhost:5681 \
  --skip-verify \
  --overwrite
```

```sh
kumactl get zones
```