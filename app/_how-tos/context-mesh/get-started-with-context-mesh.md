---
title: "Deploy an MCP server with {{site.context_mesh}} and {{site.operator_product_name}}"
permalink: /context-mesh/get-started-with-context-mesh/
content_type: how_to
description: "Deploy a {{site.context_mesh}}-backed MCP server from the Konnect UI onto an Operator-managed data plane"
breadcrumbs:
  - /mcp/

products:
  - context-mesh
  - gateway
  - ai-gateway

works_on:
  - konnect

min_version:
  gateway: '3.13'

plugins:
  - ai-mcp-proxy

entities:
  - service
  - route
  - plugin

published: true
tags:
  - ai
  - mcp
  - kubernetes

tldr:
  q: "How do I deploy a {{site.context_mesh}}  MCP server from the Konnect UI?"
  a: "Install the nightly {{site.kong_operator}} chart with the `mcp-server` feature gate, create a Konnect-managed `DataPlane`, then use the Konnect UI to create an MCP server against that control plane."

tools:
  - operator

prereqs:
  inline:
    - title: Claude code
      content: |
        Install [{{site.claude_code}}](https://claude.ai/code) for terminal access to the MCP server.
      icon_url: /assets/icons/third-party/claude.svg
    - title: Kubernetes cluster
      content: |
        Set up a local Kubernetes cluster using one of these options:

        **Kind**

        ```bash
        kind create cluster --name context-mesh-demo
        ```

        **Minikube**

        ```bash
        minikube start --cpus=4 --memory=8192
        ```

        **Docker Desktop**

        1. Open Docker Desktop preferences
        2. Go to **Kubernetes** tab
        3. Enable Kubernetes
        4. Wait for it to be ready (shows "Kubernetes is running")
      icon_url: /assets/icons/kubernetes.svg
    - title: OpenWeatherMap account
      content: |
        1. Create an account at [openweathermap.org](https://home.openweathermap.org/users/sign_in)
        2. Generate an API key (may take several hours to activate)

        {% env_variables %}
        OPENWEATHERMAP_API_KEY: <your-api-key>
        {% endenv_variables %}
    - title: OpenWeather OpenAPI spec
      content: |
        Save the following as `openweathermap.json`:

        ```json
        {
          "openapi": "3.1.0",
          "info": {
            "title": "OpenWeatherMap One Call API",
            "description": "Provides access to current weather, hourly forecast, and daily forecast data.",
            "version": "v1.0.0"
          },
          "servers": [
            {
              "url": "https://api.openweathermap.org"
            }
          ],
          "paths": {
            "/data/2.5/weather": {
              "get": {
                "description": "Retrieve current weather, hourly forecast, and daily forecast based on latitude and longitude.",
                "operationId": "getWeatherData",
                "parameters": [
                  {
                    "name": "lat",
                    "in": "query",
                    "required": true,
                    "description": "Latitude of the location.",
                    "schema": {
                      "type": "number"
                    }
                  },
                  {
                    "name": "lon",
                    "in": "query",
                    "required": true,
                    "description": "Longitude of the location.",
                    "schema": {
                      "type": "number"
                    }
                  },
                  {
                    "name": "appid",
                    "in": "query",
                    "required": true,
                    "description": "API key for authentication.",
                    "schema": {
                      "type": "string"
                    }
                  }
                ],
                "responses": {
                  "200": {
                    "description": "Successful response with weather data.",
                    "content": {
                      "application/json": {
                        "schema": {
                          "$ref": "#/components/schemas/WeatherResponse"
                        }
                      }
                    }
                  },
                  "401": {
                    "description": "Unauthorized due to missing or invalid API key."
                  }
                }
              }
            }
          },
          "components": {
            "securitySchemes": {
              "apiKeyAuth": {
                "type": "apiKey",
                "in": "query",
                "name": "appid"
              }
            },
            "schemas": {
              "WeatherResponse": {
                "type": "object",
                "properties": {
                  "current": {
                    "type": "object",
                    "properties": {
                      "lat": {
                        "type": "number"
                      },
                      "lon": {
                        "type": "number"
                      },
                      "tz": {
                        "type": "string"
                      },
                      "date": {
                        "type": "string",
                        "format": "date"
                      },
                      "units": {
                        "type": "string"
                      },
                      "cloud_cover": {
                        "type": "object",
                        "properties": {
                          "afternoon": {
                            "type": "integer"
                          }
                        }
                      },
                      "humidity": {
                        "type": "object",
                        "properties": {
                          "afternoon": {
                            "type": "integer"
                          }
                        }
                      },
                      "precipitation": {
                        "type": "object",
                        "properties": {
                          "total": {
                            "type": "integer"
                          }
                        }
                      },
                      "temperature": {
                        "type": "object",
                        "properties": {
                          "min": { "type": "number" },
                          "max": { "type": "number" },
                          "afternoon": { "type": "number" },
                          "night": { "type": "number" },
                          "evening": { "type": "number" },
                          "morning": { "type": "number" }
                        }
                      },
                      "pressure": {
                        "type": "object",
                        "properties": {
                          "afternoon": {
                            "type": "integer"
                          }
                        }
                      },
                      "wind": {
                        "type": "object",
                        "properties": {
                          "max": {
                            "type": "object",
                            "properties": {
                              "speed": { "type": "number" },
                              "direction": { "type": "integer" }
                            }
                          }
                        }
                      }
                    }
                  },
                  "hourly": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "properties": {
                        "lat": {
                          "type": "number"
                        },
                        "lon": {
                          "type": "number"
                        },
                        "tz": {
                          "type": "string"
                        },
                        "date": {
                          "type": "string",
                          "format": "date"
                        },
                        "units": {
                          "type": "string"
                        },
                        "cloud_cover": {
                          "type": "object",
                          "properties": {
                            "afternoon": {
                              "type": "integer"
                            }
                          }
                        },
                        "humidity": {
                          "type": "object",
                          "properties": {
                            "afternoon": {
                              "type": "integer"
                            }
                          }
                        },
                        "precipitation": {
                          "type": "object",
                          "properties": {
                            "total": {
                              "type": "integer"
                            }
                          }
                        },
                        "temperature": {
                          "type": "object",
                          "properties": {
                            "min": { "type": "number" },
                            "max": { "type": "number" },
                            "afternoon": { "type": "number" },
                            "night": { "type": "number" },
                            "evening": { "type": "number" },
                            "morning": { "type": "number" }
                          }
                        },
                        "pressure": {
                          "type": "object",
                          "properties": {
                            "afternoon": {
                              "type": "integer"
                            }
                          }
                        },
                        "wind": {
                          "type": "object",
                          "properties": {
                            "max": {
                              "type": "object",
                              "properties": {
                                "speed": { "type": "number" },
                                "direction": { "type": "integer" }
                              }
                            }
                          }
                        }
                      }
                    }
                  },
                  "daily": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "properties": {
                        "lat": {
                          "type": "number"
                        },
                        "lon": {
                          "type": "number"
                        },
                        "tz": {
                          "type": "string"
                        },
                        "date": {
                          "type": "string",
                          "format": "date"
                        },
                        "units": {
                          "type": "string"
                        },
                        "cloud_cover": {
                          "type": "object",
                          "properties": {
                            "afternoon": {
                              "type": "integer"
                            }
                          }
                        },
                        "humidity": {
                          "type": "object",
                          "properties": {
                            "afternoon": {
                              "type": "integer"
                            }
                          }
                        },
                        "precipitation": {
                          "type": "object",
                          "properties": {
                            "total": {
                              "type": "integer"
                            }
                          }
                        },
                        "temperature": {
                          "type": "object",
                          "properties": {
                            "min": { "type": "number" },
                            "max": { "type": "number" },
                            "afternoon": { "type": "number" },
                            "night": { "type": "number" },
                            "evening": { "type": "number" },
                            "morning": { "type": "number" }
                          }
                        },
                        "pressure": {
                          "type": "object",
                          "properties": {
                            "afternoon": {
                              "type": "integer"
                            }
                          }
                        },
                        "wind": {
                          "type": "object",
                          "properties": {
                            "max": {
                              "type": "object",
                              "properties": {
                                "speed": { "type": "number" },
                                "direction": { "type": "integer" }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        ```
        {:.collapsible}
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Proxy
    url: /plugins/ai-mcp-proxy/

cleanup:
  inline:
    - title: Remove MCP server
      content: |
        To remove an MCP server, open it in the {{site.konnect_short_name}} UI and delete it. This disassociates the MCP server from its control plane but keeps the {{site.konnect_short_name}} record.
      icon_url: /assets/icons/gateway.svg
    - title: Clean up Kubernetes resources
      content: |
        To tear down the cluster-side resources:

        ```shell
        kubectl delete dataplane dataplane -n default
        kubectl delete konnectextension my-konnect-config -n default
        kubectl delete konnectgatewaycontrolplane test -n default
        kubectl delete konnectapiauthconfiguration konnect-api-auth -n default
        helm uninstall kong-operator -n kong-system
        kubectl delete namespace kong-system
        ```

        Deleting the `KonnectGatewayControlPlane` removes the control plane from {{site.konnect_short_name}} as well.
      icon_url: /assets/icons/gateway.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
---

## Install {{site.kong_operator}}

```shell
helm repo update
helm upgrade --install kong-operator \
  kong/kong-operator \
  --set image.tag=2.2 \
  --set env.FEATURE_GATES=mcp-server \
  --set env.ENABLE_CONTROLLER_KONNECT=true \
  --create-namespace \
  --namespace kong-system
```

Confirm the Operator pod is running:

```shell
kubectl get pods -n kong-system
```

## Create the Konnect-managed control plane and data plane

Apply the manifest below. It creates a `KonnectAPIAuthConfiguration` holding your token, a `KonnectGatewayControlPlane` that the Operator mirrors into {{site.konnect_short_name}}, a `KonnectExtension` linking the data plane to that control plane, and a `DataPlane` running three {{site.base_gateway}} replicas.

```shell
kubectl apply -f - <<EOF
kind: KonnectAPIAuthConfiguration
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: konnect-api-auth
  namespace: default
spec:
  type: token
  token: ${KONNECT_TOKEN}
  serverURL: us.api.konghq.tech
---
kind: KonnectGatewayControlPlane
apiVersion: konnect.konghq.com/v1alpha2
metadata:
  name: test
  namespace: default
spec:
  createControlPlaneRequest:
    name: context-mesh-demo
    labels:
      app: context-mesh-demo
  konnect:
    authRef:
      name: konnect-api-auth
---
kind: KonnectExtension
apiVersion: konnect.konghq.com/v1alpha2
metadata:
  name: my-konnect-config
  namespace: default
spec:
  konnect:
    controlPlane:
      ref:
        type: konnectNamespacedRef
        konnectNamespacedRef:
          name: test
---
apiVersion: gateway-operator.konghq.com/v1beta1
kind: DataPlane
metadata:
  name: dataplane
  namespace: default
spec:
  extensions:
  - kind: KonnectExtension
    name: my-konnect-config
    group: konnect.konghq.com
  deployment:
    replicas: 3
    podTemplateSpec:
      spec:
        containers:
        - name: proxy
          image: kong/kong-gateway:3.13
EOF
```

{:.info}
> For the EU or AU {{site.konnect_short_name}} region, set `serverURL` to `eu.api.konghq.com` or `au.api.konghq.com`.

Wait for the data plane to reach `Ready`:

```shell
kubectl wait --timeout=3m dataplane dataplane --for=condition=Ready
```

## Create the OpenWeather {{site.context_mesh}} server

1. In {{site.konnect_short_name}}, go to **{{site.context_mesh}}** > **MCP Servers**
1. Select **New MCP server**.
1. In the **Add a source** section, click the hyperlink to add a new source.
1. Select the **Upload new** tab and upload the `openweathermap.json`.
1. Click **Add Source**.
1. Select the OpenWeather API in the New MCP server wizard.
1. Click **Next**;
1. Name the server `openweather-service`.
1. Select the Operator-managed control plane (`context-mesh-demo`).
1. Click **Create server** and wait for the server status to become **Healthy**.

The MCP runtime is now exposed at `http://localhost:8080/mcp`.

## Set up port forwarding

To access the MCP server locally, you need to set up port forwarding from your machine to the Kubernetes cluster.

### Verify the data plane is running

Check that all three data plane pods are in `Running` status:

```shell
kubectl get pods -n default
```

Expected output:

```
NAME                                                              READY   STATUS    RESTARTS   AGE
dataplane-dataplane-dr7h6-566d4fc8f5-44ngp                        1/1     Running   0          17h
dataplane-dataplane-dr7h6-566d4fc8f5-j4qtf                        1/1     Running   0          17h
dataplane-dataplane-dr7h6-566d4fc8f5-v9wk4                        1/1     Running   0          17h
```

{:.warning}
> If pods are in `Pending` or `CrashLoopBackOff` status, wait a few minutes or check the pod logs: `kubectl logs -n default <pod-name>`

### Check the MCP server service

Verify the MCP server service is created and running:

```shell
kubectl get svc -n default
```

Expected output:

```
NAME                                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes                              ClusterIP   10.96.0.1       <none>        443/TCP    19h
mcpserver-test-45675cb3                 ClusterIP   10.96.127.86    <none>        8080/TCP   57m
```

The MCP server service name is `mcpserver-test-45675cb3` and runs on port `8080`.

### Set up port forwarding

Set up `kubectl` port forwarding to the MCP server service. This forwards local port 8080 to the MCP server:

```shell
kubectl port-forward svc/mcpserver-test-45675cb3 8080:8080
```

Expected output:

```
Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080
```

{:.info}
> Run this command in a separate terminal and leave it running. The port forwarding must stay active while you use the MCP server.

### Test the connection

In another terminal, test that the MCP endpoint is now accessible:

```shell
curl -i http://localhost:8080/mcp
```

Expected output when the server is ready:

```
HTTP/1.1 404 Not Found
date: Fri, 29 May 2026 04:46:25 GMT
server: uvicorn
content-length: 9
content-type: text/plain; charset=utf-8

Not Found
```

{:.info}
> The `404` response is expected. It confirms the MCP server is accessible and running.

## Connect an agent to the OpenWeather MCP server

Once port forwarding is active and the server is responding, register the MCP server with Claude Code:

```bash
claude mcp add --transport http context-mesh-weather http://localhost:8080/mcp \
  --header "X-Upstream-Api-Key: ${OPENWEATHERMAP_API_KEY}"
```

Expected output:

```
Added context-mesh-weather MCP server
```

Try a prompt in Claude Code:

```
Tell me the weather in Hawaii.
```
{:.no-copy-code}

## Troubleshoot port forwarding

If you cannot establish port forwarding:

1. Verify the MCP server pod is running:

   ```shell
   kubectl get pods -n default | grep mcpserver
   ```

   Expected output:

   ```
   mcpserver-test-45675cb3-764b4d6d6c-q2gnp                          1/1     Running   0          57m
   ```

2. Check the pod logs for errors:

   ```shell
   kubectl logs -n default mcpserver-test-45675cb3-764b4d6d6c-q2gnp
   ```

3. If the pod is in `CrashLoopBackOff` or `Pending`, wait a few minutes for it to initialize. Then retry the port forwarding.