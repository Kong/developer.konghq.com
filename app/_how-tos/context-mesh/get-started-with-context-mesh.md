---
title: "Deploy an MCP server with {{site.context_mesh}} and {{site.operator_product_name}}"
permalink: /context-mesh/get-started-with-context-mesh/
content_type: how_to
description: "Deploy the OpenWeather {{site.context_mesh}} MCP server from the Konnect UI"
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
  q: "How do I deploy the OpenWeather {{site.context_mesh}} MCP server?"
  a: "Install {{site.kong_operator}} 2.2 with the `mcp-server` feature gate, create a Konnect-managed control plane and data plane, then create the MCP server from the Konnect UI."

tools:
  - operator

prereqs:
  inline:
    - title: Konnect Personal Access Token
      content: |
        Generate a token in {{site.konnect_short_name}} and set the environment variable:

        {% env_variables %}
        KONNECT_TOKEN: kpat_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        {% endenv_variables %}
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
    - title: Claude Code
      content: |
        Install [{{site.claude_code}}](https://claude.ai/code) for terminal access to the MCP server.
      icon_url: /assets/icons/third-party/claude.svg
    - title: OpenWeatherMap account and API key
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

cleanup:
  inline:
    - title: Delete the MCP server
      content: |
        In the {{site.konnect_short_name}} UI, open the MCP server and delete it. This disassociates the MCP server from the control plane.
      icon_url: /assets/icons/gateway.svg
---

## Update the Helm repository

```shell
helm repo update
```

{:.info}
> This ensures you have the latest Kong Helm chart available locally.

## Install {{site.kong_operator}}

```shell
helm upgrade --install kong-operator \
  kong/kong-operator \
  --set image.tag=2.2 \
  --set env.FEATURE_GATES=mcp-server \
  --set env.ENABLE_CONTROLLER_KONNECT=true \
  --create-namespace \
  --namespace kong-system
```

## Deploy Konnect-connected ControlPlane and DataPlane

Apply the manifest below:

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
  serverURL: us.api.konghq.com
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
          image: kong/kong-gateway:3.14
EOF
```

## Wait for the DataPlane to be ready

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
1. Click **Next**.
1. Name the server `openweather-service`.
1. Select the Operator-managed control plane (`context-mesh-demo`).
1. Click **Create server** and wait for the server status to become **Healthy**.

The MCP runtime is now exposed at `/mcp/openweather-service`.

## Test the OpenWeather MCP server

Hook up the MCP server to an agent:

```shell
claude mcp add --transport http context-mesh-weather http://localhost/mcp/openweather-service \
  --header "X-Upstream-Api-Key: ${OPENWEATHERMAP_API_KEY}"
```

Try a prompt in Claude Code:

```
Tell me the weather in Hawaii.
```
{:.no-copy-code}
