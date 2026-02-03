---
title: CI/CD integration with kongctl
content_type: how_to
description: Integrate kongctl into CI/CD pipelines for automated Kong Konnect deployments.
tldr:
  q: What CI/CD platforms are supported?
  a: Use kongctl with GitHub Actions, GitLab CI, Jenkins, and CircleCI to automate Konnect deployments.
products:
  - konnect
tools:
  - kongctl
works_on:
  - konnect
tags:
  - ci/cd
  - declarative-config
  - automation
  - github
breadcrumbs:
  - /kongctl/
  - /kongctl/declarative/
related_resources:
  - text: Declarative configuration guide
    url: /kongctl/declarative/
  - text: Authentication guide
    url: /kongctl/authentication/
---

kongctl is designed for CI/CD integration, enabling automated deployments of {{site.konnect_short_name}} infrastructure as code.

## Authentication in CI/CD

Use personal access tokens (PATs) for non-interactive authentication in pipelines.

### Create a personal access token

1. Log in to {{site.konnect_short_name}}
2. Navigate to **Personal Access Tokens**
3. Click **Generate Token**
4. Copy the token (it's shown only once)

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

## GitLab CI/CD

Create `.gitlab-ci.yml`:

```yaml
stages:
  - plan
  - deploy

variables:
  KONGCTL_VERSION: "0.3.8"

.install_kongctl: &install_kongctl
  - curl -sL https://github.com/Kong/kongctl/releases/download/v${KONGCTL_VERSION}/kongctl_${KONGCTL_VERSION}_linux_amd64.tar.gz -o kongctl.tar.gz
  - tar -xzf kongctl.tar.gz
  - mv kongctl /usr/local/bin/
  - kongctl version

plan:
  stage: plan
  image: ubuntu:22.04
  before_script:
    - apt-get update && apt-get install -y curl
    - *install_kongctl
  script:
    - kongctl plan -f config/ --output-file plan.json
  artifacts:
    paths:
      - plan.json
    expire_in: 1 week
  only:
    - merge_requests
    - main

deploy:
  stage: deploy
  image: ubuntu:22.04
  before_script:
    - apt-get update && apt-get install -y curl
    - *install_kongctl
  script:
    - kongctl apply --plan plan.json
  dependencies:
    - plan
  only:
    - main
  when: manual
```

Add `KONGCTL_DEFAULT_KONNECT_PAT` as a CI/CD variable in project settings.

## Jenkins

Create `Jenkinsfile`:

```bash
pipeline {
    agent any

    environment {
        KONGCTL_DEFAULT_KONNECT_PAT = credentials('konnect-pat')
        KONGCTL_VERSION = '0.3.8'
    }

    stages {
        stage('Install kongctl') {
            steps {
                sh '''
                    curl -sL https://github.com/Kong/kongctl/releases/download/v${KONGCTL_VERSION}/kongctl_${KONGCTL_VERSION}_linux_amd64.tar.gz -o kongctl.tar.gz
                    tar -xzf kongctl.tar.gz
                    chmod +x kongctl
                '''
            }
        }

        stage('Plan') {
            steps {
                sh './kongctl plan -f config/ --output-file plan.json'
                archiveArtifacts artifacts: 'plan.json'
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to Konnect?', ok: 'Deploy'
                sh './kongctl apply --plan plan.json'
            }
        }
    }
}
```

## CircleCI

Create `.circleci/config.yml`:

```yaml
version: 2.1

executors:
  kongctl:
    docker:
      - image: cimg/base:2024.01

commands:
  install-kongctl:
    steps:
      - run:
          name: Install kongctl
          command: |
            curl -sL https://github.com/Kong/kongctl/releases/download/v0.3.8/kongctl_0.3.8_linux_amd64.tar.gz -o kongctl.tar.gz
            tar -xzf kongctl.tar.gz
            sudo mv kongctl /usr/local/bin/
            kongctl version

jobs:
  plan:
    executor: kongctl
    steps:
      - checkout
      - install-kongctl
      - run:
          name: Generate plan
          command: kongctl plan -f config/ --output-file plan.json
      - persist_to_workspace:
          root: .
          paths:
            - plan.json
      - store_artifacts:
          path: plan.json

  deploy:
    executor: kongctl
    steps:
      - checkout
      - install-kongctl
      - attach_workspace:
          at: .
      - run:
          name: Apply plan
          command: kongctl apply --plan plan.json

workflows:
  deploy-konnect:
    jobs:
      - plan
      - deploy:
          requires:
            - plan
          filters:
            branches:
              only: main
```

## Best practices

### Use plan artifacts

Generate plans in pull requests, review them, then apply the exact plan:

```bash
# In PR
kongctl plan -f config/ --output-file plan.json

# After review and merge
kongctl apply --plan plan.json
```

### Separate environments

Use different configurations or namespaces per environment:

```
config/
├── dev/
│   └── resources.yaml
├── staging/
│   └── resources.yaml
└── production/
    └── resources.yaml
```

Deploy with:
```bash
kongctl apply -f config/production/
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

### GitHub Actions with environments

```yaml
jobs:
  deploy-dev:
    environment: dev
    steps:
      - run: kongctl apply -f config/dev/

  deploy-staging:
    environment: staging
    needs: deploy-dev
    steps:
      - run: kongctl apply -f config/staging/

  deploy-production:
    environment: production
    needs: deploy-staging
    steps:
      - run: kongctl apply -f config/production/
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
* [Authentication guide](/kongctl/authentication/)
* [Environment variables reference](/kongctl/reference/environment-variables/)
* [GitHub Actions example](https://github.com/Kong/kongctl/tree/main/docs/examples)
