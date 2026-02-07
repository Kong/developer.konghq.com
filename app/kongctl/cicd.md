---
title: CI/CD integration with kongctl
description: Integrate kongctl into CI/CD pipelines for automated {{site.konnect_product_name}} deployments

content_type: reference
layout: reference

beta: true

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/

products:
  - konnect

tags:
  - ci/cd
  - declarative-config
  - automation
  - github

related_resources:
  - text: Declarative configuration guide
    url: /kongctl/declarative/
---

kongctl is designed for CI/CD integration, enabling automated deployments of {{site.konnect_short_name}} infrastructure as code.

## Authentication in CI/CD

Use [access tokens (personal or system)](/konnect-api/#personal-access-tokens) for non-interactive authentication in pipelines.

### Configure in CI/CD

Set the token as an environment variable:

```bash
export KONGCTL_DEFAULT_KONNECT_PAT="kpat_your-token-here"
```

Or pass it via flag:

```bash
kongctl plan -f config/ --pat "$KONNECT_PAT"
```

{:.warning}
> **Security**: Store tokens as encrypted secrets in your CI/CD platform. Never commit tokens to version control.

## GitHub Actions

### Basic workflow

Create `.github/workflows/deploy-konnect.yml`:

```yaml
name: Deploy to Konnect

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install kongctl
        run: |
          curl -sL https://github.com/Kong/kongctl/releases/download/v0.3.8/kongctl_0.3.8_linux_amd64.tar.gz -o kongctl.tar.gz
          tar -xzf kongctl.tar.gz
          sudo mv kongctl /usr/local/bin/
          kongctl version

      - name: Generate plan
        env:
          KONGCTL_DEFAULT_KONNECT_PAT: ${{ secrets.KONNECT_PAT }}
        run: |
          kongctl plan -f config/ --output-file plan.json

      - name: Upload plan artifact
        uses: actions/upload-artifact@v4
        with:
          name: konnect-plan
          path: plan.json

      - name: Comment plan on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const plan = JSON.parse(fs.readFileSync('plan.json', 'utf8'));
            const comment = `## Konnect Deployment Plan\n\n\`\`\`\n${JSON.stringify(plan, null, 2)}\n\`\`\``;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });

  deploy:
    runs-on: ubuntu-latest
    needs: plan
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Install kongctl
        run: |
          curl -sL https://github.com/Kong/kongctl/releases/download/v0.3.8/kongctl_0.3.8_linux_amd64.tar.gz -o kongctl.tar.gz
          tar -xzf kongctl.tar.gz
          sudo mv kongctl /usr/local/bin/

      - name: Download plan
        uses: actions/download-artifact@v4
        with:
          name: konnect-plan

      - name: Apply plan
        env:
          KONGCTL_DEFAULT_KONNECT_PAT: ${{ secrets.KONNECT_PAT }}
        run: |
          kongctl apply --plan plan.json
```

### Secrets setup

Add `KONNECT_PAT` to GitHub repository secrets:

1. Go to repository **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `KONNECT_PAT`
4. Value: Your personal access token
5. Click **Add secret**

## Best practices

### Use plan artifacts

Generate plans in pull requests, review them, then apply the exact plan:

```bash
# In PR
kongctl plan -f config/ --output-file plan.json

# After review and merge
kongctl apply --plan plan.json
```

### Add approval gates

Require manual approval before production deployments:

```yaml
# GitHub Actions
deploy:
  environment:
    name: production
    approval: required
```

### Version control plans

Commit plan artifacts for audit trails:

```bash
kongctl plan -f config/ --output-file plan.json
git add plan.json
git commit -m "Add deployment plan for v1.2.0"
```

### Use namespace isolation

If multiple teams use the same {{site.konnect_short_name}} organization, isolate resources by naming convention or separate configurations.

### Validate before deploying

Add validation steps:

```bash
# Validate YAML syntax
yamllint config/

# Generate plan to catch errors
kongctl plan -f config/

# Then apply
kongctl apply -f config/
```

## Multi-environment example

### Directory structure

```
konnect-config/
├── base/
│   └── common.yaml
├── dev/
│   └── overrides.yaml
├── staging/
│   └── overrides.yaml
└── production/
    └── overrides.yaml
```

## Troubleshooting

### Authentication failures

Verify token is set:
```bash
echo $KONGCTL_DEFAULT_KONNECT_PAT | head -c 20
```

Test authentication:
```bash
kongctl get me
```

### Plan/apply mismatches

If applying a plan fails with "state changed", regenerate the plan:
```bash
kongctl plan -f config/ --output-file plan.json
kongctl apply --plan plan.json
```

### Concurrent deployments

Avoid running multiple deployments simultaneously. Use pipeline locks or queues.

## Related resources

* [Declarative configuration guide](/kongctl/declarative/)
* [Configuration guide](/kongctl/config/)
* [Environment variables reference](/kongctl/reference/environment-variables/)
* [GitHub Actions example](https://github.com/Kong/kongctl/tree/main/docs/examples)
