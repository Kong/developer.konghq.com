[Mise](https://mise.jdx.dev/) is a polyglot tool version manager. If you're already using mise, you can install kongctl with it.

Install the latest version:

```bash
mise use -g github:Kong/kongctl@latest
```

Or install a specific version:

```bash
mise use -g github:Kong/kongctl@{{site.data.kongctl_latest.version}}
```

Verify the installation:

```bash
kongctl version --full
```
