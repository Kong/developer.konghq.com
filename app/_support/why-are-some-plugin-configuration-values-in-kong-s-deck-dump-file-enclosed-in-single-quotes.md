---
title: "Single quotes around plugin configuration values in Kong's deck dump file"
content_type: support
description: "When working with Kong's deck dump files, especially for plugins like the OpenID Connect plugin, you might notice that some configuration values are enclosed in single quotes."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why are some plugin configuration values in Kong's deck dump file enclosed in single quotes?"
  a: |
    deck dump files use YAML, and per the YAML 1.2 specification certain characters can cause the parser
    to misinterpret an unquoted string as a different data type or structure. To prevent this, YAML encloses
    such strings in quotes to ensure they are parsed correctly. This happens for values containing characters
    like `#`, `:`, `{`, `}`, `[`, `]`, `!`, `%`, `@`, and others, as well as leading zeros in numeric strings
    or strings matching `true`, `false`, `on`, `off`, or `null`. For example, the value `}E]0Y1a$-P` appears
    as `'}E]0Y1a$-P'` in the dump.
related_resources:
  - text: "YAML 1.2 specification"
    url: "https://yaml.org/spec/1.2.2/"
---

## Single quotes around plugin configuration values in a deck dump file

When working with Kong's deck dump files, especially for plugins like the OpenID Connect plugin, you might notice that some configuration values are enclosed in single quotes. This behavior is particularly observed when values start with characters such as `!` or `}`. Understanding why this happens requires a bit of insight into how YAML, the format used by deck dump files, handles data. YAML is designed to be easily readable by humans and is used by Kong's underlying libraries to parse the configuration data output by the `deck` command. According to the YAML 1.2 specification, certain characters can cause the YAML parser to misinterpret unquoted strings as different data types or structures. To prevent this, YAML encloses strings that start with or contain these characters in quotes. This ensures the correct parsing and handling of these values.

Here are some common scenarios where you'll see values enclosed in quotes in a YAML file:

- Characters such as `#`, `:`, `{`, `}`, `[`, `]`, `,`, `&`, `*`, `?`, `|`, `-`, ``, `=`, `!`, `%`, `@`, `` ` ``, along with any quote character (`'` or `"`), can trigger this behavior.
- Leading zeros in purely numeric strings.
- Strings that match boolean values (`true`, `false`, `on`, `off`) or `null` values exactly.

For example, if you have a configuration value for `TokenPostArgsValues` set as `}E]0Y1a$-P`, in the deck dump file, it will appear as:

```yaml
token_post_args_values:
  - '}E]0Y1a$-P'
```

This quoting is necessary to ensure that the YAML parser correctly interprets the value as a string rather than mistakenly treating it as a different data type or structure. For a comprehensive understanding of all characters and scenarios that might cause a value to be quoted, refer to the YAML 1.2 specification. This explanation clarifies why certain values in Kong's deck dump files are enclosed in single quotes, ensuring accurate parsing and handling of configuration data.
