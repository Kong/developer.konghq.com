---
title: "File values and path boundaries with kongctl"
description: "Load file content, extract values, and choose path boundaries."
content_type: reference
layout: reference
works_on:
  - konnect
tools:
  - kongctl
breadcrumbs:
  - /kongctl/
  - /kongctl/declarative/
related_resources:
  - text: Declarative configuration overview
    url: /kongctl/declarative/
  - text: Supported resources
    url: /kongctl/supported-resources/
---

Read this page when loading text or structured values with `!file`, or resolving
file paths and base directory errors.

## Loading file content to YAML fields

Load the entire content of a file as a string:

```yaml
apis:
  - ref: users-api
    name: "Users API"
    description: !file ./docs/api-description.md
```
All file paths are resolved relative to the directory containing the
configuration file:

```
project/
├── config.yaml          # Main config file
├── specs/
│   ├── users-api.yaml
│   └── products-api.yaml
└── docs/
    └── descriptions.txt
```

In `config.yaml`:

```yaml
apis:
  - ref: users-api
    name: !file ./specs/users-api.yaml#info.title
    description: !file ./docs/descriptions.txt
```

Supported file types: Any text file (`.txt`, `.md`, `.yaml`, `.json`, etc.)

### Security features

**Path Traversal Prevention**: Absolute paths are blocked. Relative paths may
include `..`, but the resolved path must stay within the base directory
boundary. By default, the boundary is the root of each `-f` source (file: its
parent dir, dir: the directory itself). For stdin and URL sources, the boundary
defaults to the current working directory. Set the base directory with
`--base-dir` or `konnect.declarative.base-dir`
(`KONGCTL_<PROFILE>_KONNECT_DECLARATIVE_BASE_DIR`, for example
`KONGCTL_DEFAULT_KONNECT_DECLARATIVE_BASE_DIR`). When URL sources are loaded
with `--remote-file-save-dir`, subsequent relative paths are resolved like
normal file sources from the save directory.

```yaml
# ❌ These will fail with security errors
description: !file /etc/passwd
```

```yaml
# ❌ This will fail if it resolves outside the base directory
config: !file ../../../sensitive/file.yaml
```

```yaml
# ✅ These are allowed (if they stay within the base directory)
description: !file ../docs/description.txt
config: !file ./config/settings.yaml
```

**File Size Limits**: Files are limited to 10MB.

### Performance features

**File Caching**: Files are cached during a single execution to improve
performance:

```yaml
apis:
  - ref: api-1
    name: !file ./common.yaml#api.name        # File loaded and cached
    description: !file ./common.yaml#api.desc # Uses cached version
  - ref: api-2
    description: !file ./common.yaml#api.desc       # Uses cached version
```

### Value extraction

You can extract specific values from structured data loaded from the `file` tag
with this hash (`#`) notation:

```yaml
apis:
  - ref: users-api
    name: !file ./specs/openapi.yaml#info.title # loads info.title field from the openapi.yaml file
    description: !file ./specs/openapi.yaml#info.description
    version: !file ./specs/openapi.yaml#info.version

    versions:
      - ref: v1
        spec: !file ./specs/openapi.yaml
```

Alternatively values can be extracted using this map format:

```yaml
apis:
  - ref: products-api
    name: !file
      path: ./specs/products.yaml
      extract: info.title
    labels:
      contact: !file
        path: ./specs/products.yaml
        extract: info.contact.email
```
