---
title: Learn how to create a Terraform manifest for Konnect
related_resources:
  - text: Terraform provider
    url: /terraform/

products:
  - konnect

platforms:
  - konnect

tools:
  - terraform

entities: 
  - service
  - route

tags:
  - terraform
  - beginner

tldr: 
  q: asdf
  a: asdf

faqs:
  - q: "`terraform init` fails with an error like `Failed to authenticate`."
    a: "Double-check your `kong_admin_url` and token values in `main.tf`. Ensure there arn't typos and that the token is valid."
  - q:
    a: 
---

cover what the tutorial will talk about, what you will learn

## Set up your prerequisites

Need to explain the prereqs, why do you need these?

1. Install Terraform if it's not already installed. Follow the instructions in the Terraform Installation Guide.

1. Obtain an API token from your Konnect account:

## Initialize Your Terraform Project

What is this doing?

1. Create a directory for your project:
  ```sh
  mkdir kong-konnect-terraform
  cd kong-konnect-terraform
  ```

1. Create a `main.tf` file:
  ```sh
  touch main.tf
  ```

  This file will contain the main configuration for Terraform.

1. Define the Terraform provider by opening `main.tf` and adding the following:
  ```hcl
    terraform {
      required_providers {
        konnect = {
          source  = "kong/konnect"
        }
      }
    }

    provider "konnect" {
      personal_access_token = "kpat_YOUR_PAT"
      server_url            = "https://us.api.konghq.com"
    }
  ```

  This tells Terraform to use Kong as a provider and provides necessary connection details. `kong_admin_url` is the URL for your Kong Admin API, and `token` is your authentication token. These settings enable Terraform to communicate with your Kong instance.

1. Initialize Terraform:
  ```bash
   terraform init
   ```

   This downloads the provider plugins specified in your configuration and prepares your working directory for other Terraform commands.



<!-- all draft content below to pick through 

## Step 2: Define a Kong Service

### Actions

1. **Create a `service.tf` File**:
   ```bash
   touch service.tf
   ```

2. **Add the Service Configuration**:
   Open `service.tf` and add the following content:
   ```hcl
   resource "kong_service" "my_service" {
     name = "my-service"
     url  = "https://example.com"
   }
   ```

3. **Apply the Configuration**:
   ```bash
   terraform apply
   ```

   Confirm the apply action.

### Explanation

- **Create a `service.tf` File**: This file will define your Kong service resources.
- **Add the Service Configuration**: This block defines a new Kong service named `my-service` with a target URL of `https://example.com`. A service in Kong represents an upstream API or service that Kong will proxy requests to.
- **Apply the Configuration**: This command creates the service in Kong Konnect as specified. By applying the configuration, you are making sure that Terraform sets up the service in your Kong instance.

## Step 3: Define a Kong Route

### Actions

1. **Create a `route.tf` File**:
   ```bash
   touch route.tf
   ```

2. **Add the Route Configuration**:
   Open `route.tf` and add the following content:
   ```hcl
   resource "kong_route" "my_route" {
     name      = "my-route"
     service   = kong_service.my_service.id
     paths     = ["/my-path"]
     protocols = ["http"]
   }
   ```

3. **Apply the Configuration**:
   ```bash
   terraform apply
   ```

   Confirm the apply action.

### Explanation

- **Create a `route.tf` File**: This file will define your Kong route resources.
- **Add the Route Configuration**: This block creates a new Kong route named `my-route` that maps to the previously defined service (`my-service`). The `paths` attribute specifies the URL path that will be matched to this route, and `protocols` specifies the protocols the route supports (HTTP in this case). Routes tell Kong how to handle requests and where to forward them.
- **Apply the Configuration**: This command creates the route in Kong based on the defined configuration. It ensures that the route correctly points to the service you set up earlier.

## Step 4: Define a Kong Plugin

### Actions

1. **Create a `plugin.tf` File**:
   ```bash
   touch plugin.tf
   ```

2. **Add the Plugin Configuration**:
   Open `plugin.tf` and add the following content:
   ```hcl
   resource "kong_plugin" "my_plugin" {
     name     = "rate-limiting"
     service  = kong_service.my_service.id
     route    = kong_route.my_route.id
     config = {
       minute = 5
     }
   }
   ```

3. **Apply the Configuration**:
   ```bash
   terraform apply
   ```

   Confirm the apply action.

### Explanation

- **Create a `plugin.tf` File**: This file will define your Kong plugin resources.
- **Add the Plugin Configuration**: This block configures a rate-limiting plugin for the specified service and route. The `config` section specifies that the plugin should limit requests to 5 per minute. Plugins add additional functionality to your services and routes, such as rate limiting, authentication, or logging.
- **Apply the Configuration**: This command applies the plugin configuration to Kong, enabling rate limiting for the route associated with your service.

## Step 5: Verify Your Configuration

### Actions

1. **Check the Service**:
   Use the Kong Konnect admin API or UI to verify that the service has been created.

2. **Check the Route**:
   Verify that the route is correctly pointing to the service.

3. **Check the Plugin**:
   Confirm that the plugin is attached to the route and has the correct configuration.

### Explanation

- **Check the Service**: Ensure that the service is correctly created and accessible in Kong. This confirms that the service configuration was applied correctly.
- **Check the Route**: Verify that the route is pointing to the correct service and has the expected URL path. This ensures that the routing setup is correct.
- **Check the Plugin**: Confirm that the plugin is active and configured correctly for the route. This step validates that the plugin's settings are applied as intended and functioning.

## Troubleshooting

- **If you encounter issues during `terraform apply`,** review the error message for details on what might be wrong. Common issues include incorrect API tokens, misconfigured URLs, or invalid configurations in your `.tf` files.
- **Check the Terraform documentation** and the [Kong Konnect Terraform Provider documentation](https://registry.terraform.io/providers/konghq/kong/latest/docs) for more details on resource configuration.

## Conclusion

You have successfully configured Kong Konnect with Terraform by setting up a service, route, and plugin. Each step builds upon the previous one, ensuring that your Kong instance is correctly configured for your needs. You can further extend this setup by adding more services, routes, and plugins as required.

-->







