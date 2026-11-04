# Automated tests

We run automated tests against our how-to guides to make sure the instructions still work. The test harness itself (how tests are extracted from pages, how to run them locally, how to author testable steps) is documented in [`tools/automated-tests/README.md`](../tools/automated-tests/README.md).

This page covers running the tests through GitHub Actions, either on demand or on their schedules.

## Workflows

| Workflow | File |
|---|---|
| [Scheduled Automated Tests](https://github.com/Kong/developer.konghq.com/actions/workflows/automated-tests.yaml) | `.github/workflows/automated-tests.yaml` | 
| [Gateway Automated Tests](https://github.com/Kong/developer.konghq.com/actions/workflows/gateway-tests.yaml) | `.github/workflows/gateway-tests.yaml` |
| [AI Gateway Automated Tests](https://github.com/Kong/developer.konghq.com/actions/workflows/ai-gateway-automated-tests.yaml) | `.github/workflows/ai-gateway-automated-tests.yaml` | 
| [Event Gateway Automated Tests](https://github.com/Kong/developer.konghq.com/actions/workflows/event-gateway-tests.yaml) | `.github/workflows/event-gateway-tests.yaml` |
| [Build Automated Tests Docker Image](https://github.com/Kong/developer.konghq.com/actions/workflows/build-automated-tests-image.yaml) | `.github/workflows/build-automated-tests-image.yaml` | 

Every workflow can also be triggered manually from the **Actions** tab in GitHub (**Run workflow**), or with the GitHub CLI, e.g.:

```bash
gh workflow run event-gateway-tests.yaml --repo Kong/developer.konghq.com
```

The `Scheduled Automated Tests` workflow runs the on-prem Gateway suite against the version in its matrix; it takes no inputs. Use the product-specific workflows when you need control over the image or target environment.