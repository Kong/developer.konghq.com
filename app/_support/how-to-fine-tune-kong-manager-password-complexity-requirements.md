---
title: How to fine tune Kong Manager password complexity requirements
content_type: support
description: Configure the `admin_gui_auth_password_complexity` setting to control password complexity requirements for Kong Manager administrators using basic authentication.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: the Kong docs
    url: /gateway/configuration/#admin-gui-auth-password-complexity
  - text: the `passwdqc.conf` documentation
    url: https://manpages.debian.org/bullseye/passwdqc/passwdqc.conf.5.en.html
tldr:
  q: How do I fine tune the password complexity requirements for Kong Manager when using basic authentication?
  a: |
    Set the `admin_gui_auth_password_complexity` Kong Manager configuration property to control password complexity for Kong Manager administrators — either using one of Kong's built-in presets (for example `min_8`) or fine-grained `min`/`max`/`passphrase` rules based on how many character classes a password uses, modeled on Debian's `passwdqc.conf` implementation. This setting can't restrict password reuse or block account-name passwords.
---

## Overview

How do I fine tune the password complexity requirements for Kong Manager when using basic authentication?

## Steps

Kong can be set up to have some control over the password complexity requirements for administrators of Kong Manager.

The parameter which sets the behavior is: `admin_gui_auth_password_complexity`

The following behaviors cannot be set/changed:

- Restrict password re-use against the previous X passwords that have been used.
- Passwords can be account names.

Kong's password complexity implementation is based on the implementation outlined here.

The Basics

There are 3 options that can be set: `min`, `max` and `passphrase`

The `max` option defines the maximum number of characters any password can have.

The `passphrase` option defines the number of words each passphrase must have.

The `min` option defines the minimum number of characters a password can have, but it does it in several different scenarios.

There are 4 character classes:

- Digits
- Lower-Case Letters
- Upper-Case Letters
- Other special characters.

Take this value: `admin_gui_auth_password_complexity = { "min": "disabled,24,11,9,8" }`

The 5 different values are described as follows:

- N0 = disabled - Passwords that consist of only 1 character class can never be long enough to satisfy the complexity requirement.
- N1 = 24 - Passwords that consist of 2 character classes need to be 24 characters in length before they satisfy the complexity requirement.
- N2 = 11 - If using Passphrases, the phrases have to be at least this length before they satisfy the complexity requirement
- N3 = 9 - Passwords that consist of 3 character classes need to be 9 characters in length before they satisfy the complexity requirement.
- N4 = 8 - Passwords that consist of all 4 character classes need to be 8 characters in length before they satisfy the complexity requirement.

Presets

Kong has several premade presets which can be used like so:

```
admin_gui_auth_password_complexity = { "kong-preset": "min_8" }
```

The Kong presets all require at least 3 character classes to be used, therefore using the above rules, we can determine that the `min_8` preset, which defines a minimum of 8 characters, looks like this when using the fine-grained rules:

```
admin_gui_auth_password_complexity = {"min":"disabled,disabled,8,8,8"}
```

If the requirement was for passwords with a minimum of 8 characters using 3 character classes and a minimum of 12 characters when using 2 character classes, the value would be defined:

```
admin_gui_auth_password_complexity = {"min":"disabled,12,8,8,8"}
```
