---
title: Authentication with kongctl
description: Learn how to authenticate kongctl to {{site.konnect_product_name}} using device flow or personal access tokens.

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
---

kongctl communications with {{site.konnect_short_name}} via the public [APIs](/api/), which
support token-based authentication. A valid token can be obtained using the following methods.

## Browser-based login (recommended)

Run the `kongctl login` command to initiate the _device code authorization flow_ with 
{{site.konnect_short_name}}.

```bash
kongctl login
```

The command will output information similar to the following, 
prompting you to open a URL in your browser providing the one-time code to authenticate.

```text
Logging your CLI into Kong Konnect with the browser...

 To login, go to the following URL in your browser:

   https://cloud.konghq.com/device-activate?code=KFVL-RXXJ

 Or copy this one-time code: KFVL-RXXJ

 And open your browser to https://cloud.konghq.com/device-activate

 (Code expires in 899 seconds)

 Waiting for user to Login...
```

After following the instructions in the browser and successfully authenticating,
you will see the message `User successfully authorized`.

kongctl has negioated with {{site.konnect_short_name}} and stored an access and refresh
token pair for subsequent commands. 

You can verify authentication by running:

```bash
kongctl get me
```

You should see your {{site.konnect_short_name}} user information.

Now you can execute kongctl commands and you will be granted access based on the permissions
of the user account you logged in with.

## Access token authentication

Access tokens come in two forms: Personal Access Tokens (PAts) 
or System Access Tokens (sPAT).

### Create a token

1. Log in to {{site.konnect_short_name}}
2. Navigate to **Personal Access Tokens**
3. Click **Generate Token**
4. Give it a descriptive name (e.g., "CI/CD Pipeline")
5. Set expiration and permissions
6. Copy the token (shown only once)

### Logout

Clear stored credentials:

```bash
kongctl logout
```

### Use via environment variable

Set the `KONGCTL_DEFAULT_KONNECT_PAT` environment variable:

```bash
export KONGCTL_DEFAULT_KONNECT_PAT="kpat_your-token-here"
```

Then run commands normally:
```bash
kongctl get apis
```

### Use via flag

Pass the token with `--pat`:

```bash
kongctl get apis --pat "kpat_your-token-here"
```

### Use in CI/CD

Store the token as a secret in your CI/CD platform:

**GitHub Actions:**

```yaml
- name: Deploy to Konnect
  env:
    KONGCTL_DEFAULT_KONNECT_PAT: ${{ secrets.KONNECT_PAT }}
  run: kongctl apply -f config/
```

{:.warning}
> **Security**: Never commit tokens to version control. Always use secrets management.

## Related resources

* [CI/CD integration guide](/kongctl/declarative/ci-cd/)
* [Environment variables reference](/kongctl/reference/environment-variables/)
