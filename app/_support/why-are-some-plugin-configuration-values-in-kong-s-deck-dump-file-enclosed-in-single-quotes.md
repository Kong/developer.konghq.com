---
title: "Single-quoted values in decK dump files"
content_type: support
description: "decK dump files use YAML, which automatically quotes strings containing special characters or values that would otherwise be misinterpreted by the YAML parser."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why are some plugin configuration values in a decK dump file enclosed in single quotes?"
  a: |
    YAML automatically quotes strings that contain special characters or match reserved values like `true`, `null`, or `on`, to prevent the parser from misinterpreting them.
related_resources:
  - text: "YAML 1.2 specification"
    url: "https://yaml.org/spec/1.2.2/"
---

## Explanation

When working with decK dump files, especially for plugins like the OpenID Connect plugin, you might notice that some configuration values are enclosed in single quotes.
decK dump files use YAML, and according to the YAML 1.2 specification, certain characters can cause the YAML parser to misinterpret an unquoted string as a different data type or structure.
To prevent this, YAML automatically encloses affected strings in quotes.

This happens in the following scenarios:

- The string contains special characters: `#`, `:`, `{`, `}`, `[`, `]`, `,`, `&`, `*`, `?`, `|`, `-`, `=`, `!`, `%`, `@`, `` ` ``, `'`, or `"`
- The string starts with leading zeros (for example, a numeric string like `007`)
- The string exactly matches a reserved word: `true`, `false`, `on`, `off`, or `null`

For example, if `token_post_args_values` is set to `}E]0Y1a$-P`, the decK dump shows:

```yaml
token_post_args_values:
  - '}E]0Y1a$-P'
```

This quoting ensures the YAML parser correctly interprets the value as a string.
For the full list of characters and scenarios that trigger quoting, see the [YAML 1.2 specification](https://yaml.org/spec/1.2.2/).
