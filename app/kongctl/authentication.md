---
title: Authentication with kongctl
description: Learn how to authenticate kongctl to {{site.konnect_product_name}} using the device flow or personal access tokens.

beta: true

content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

tags:
  - cli

breadcrumbs:
  - /kongctl/

related_resources:
  - text: kongctl configuration reference 
    url: /kongctl/config/
  - text: Manage {{site.konnect_short_name}} resources declaratively
    url: /kongctl/declarative/
  - text: kongctl configuration reference guide
    url: /kongctl/config/
  - text: kongctl troubleshooting guide
    url: /kongctl/troubleshooting/
  - text: Use kongctl and deck for full API platform management
    url: /kongctl/kongctl-and-deck/
---

kongctl communications with {{site.konnect_short_name}} via the public [APIs](/api/), which
support token-based authentication. kongctl supports two authentication methods:
* **Device Flow (recommended)**: Authenticate via your browser. Tokens are stored locally and refreshed automatically.
* **Personal Access Token**: Use the `--pat` flag or `KONGCTL_DEFAULT_KONNECT_PAT` environment variable for automation scenarios like CI/CD pipelines.
                
Configuration and device flow authentication credentials are stored in `$XDG_CONFIG_HOME/kongctl/` (typically `~/.config/kongctl/`).

## Browser-based login (recommended)

Run the `kongctl login` command to initiate the _device code authorization flow_ with 
{{site.konnect_short_name}}.

```bash
kongctl login
```

The command will output information similar to the following, 
prompting you to open a URL in your browser with the one-time code to authenticate.

```text
Logging your CLI into Kong Konnect with the browser...

 To login, go to the following URL in your browser:

   https://cloud.konghq.com/device-activate?code=KFVL-RXXJ

 Or copy this one-time code: KFVL-RXXJ

 And open your browser to https://cloud.konghq.com/device-activate

 (Code expires in 899 seconds)

 Waiting for user to Login...
```
{:.no-copy-code}

After following the instructions in the browser and successfully authenticating,
you will see the message `User successfully authorized`.

This indicates that kongctl has negotiated with {{site.konnect_short_name}} and 
stored an access and refresh token pair for subsequent commands. 

You can verify authentication by running:

```bash
kongctl get me
```

You should see your {{site.konnect_short_name}} user information.

Now you can execute kongctl commands and you will be granted access based on the permissions
of the user account you logged in with.

{:.info}
> **Info:** The tokens obtained using the browser-based method will expire. When they do you can
> simply re-exeucte the `kongctl login` procedure to obtain new tokens.

If you want to invalidate the token received from the browser-based method, 
execute the `logout` command to clear stored credentials:

```bash
kongctl logout
```

## Configured access token

[{{site.konnect_short_name}} access tokens](/konnect-api/#personal-access-tokens) come in two forms: Personal Access Tokens (PAT) or 
System Access Tokens (sPAT). PATs grant access to APIs as your personal user account, while
sPATs grant access based on the permissions of system account, which may be more 
limited than a user account. 

Use the {{site.konnect_short_name}} UI to create the token type of your choice, and 
copy the secret value:
- Create a PAT in the [personal access token page](https://cloud.konghq.com/global/account/tokens)
- Create a sPAT in the [system accounts page](https://cloud.konghq.com/global/account/system-tokens)
  or with the [System Accounts API](/api/konnect/identity/#/operations/post-system-accounts-id-access-tokens)

### Configure authentication via flag

You can pass the token with each command using the `--pat` flag:

```bash
kongctl get apis --pat "YOUR PAT HERE"
```

### Configure access token in environment variable

Store the token in an environment variable to avoid passing it with every command. For the `default` profile,
set the `KONGCTL_DEFAULT_KONNECT_PAT` environment variable:

{:.info}
> See the [environment variable configuration reference](/kongctl/config#environment-variables) 
> for full details on environment variables and the kongctl configuration system 

```bash
export KONGCTL_DEFAULT_KONNECT_PAT="YOUR PAT HERE"
```

Then run commands normally:
```bash
kongctl get apis
```

### Store the token in a configuration file

You can also store the token in the kongctl configuration file under the desired profile:

```yaml
default:
    konnect:
        pat: "YOUR PAT HERE"
``` 

{:.info}
> See the [configuration file reference](/kongctl/config#configuration-file) 
> for full details on the kongctl configuration file.

Then run commands normally:
```bash
kongctl get apis
```

{:.warning}
> **Warning**: When storing tokens in configuration files, ensure the file is 
> protected and **not** committed to version control. 
> Use this method only for local development or secure environments.

### Configure tokens in CI/CD

Store the token as a secret in your CI/CD platform.

For example, to store it as a secret in GitHub Actions:

```yaml
- name: Deploy to Konnect
  env:
    KONGCTL_DEFAULT_KONNECT_PAT: ${{ secrets.KONNECT_PAT }}
  run: kongctl apply -f config/
```

{:.warning}
> **Security**: Never commit tokens to version control. Always use secrets management.
