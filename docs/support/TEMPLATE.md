---
# REQUIRED: The title that appears at the top of the page
title: Your Support Article Title

# REQUIRED: Must be set to "support" for support articles
content_type: support

# OPTIONAL: A brief description of what this support article covers
# This appears in search results and meta tags
description: A brief description of the support article content.

# OPTIONAL: Which Kong products this article applies to
# Common values: gateway, konnect, mesh, insomnia, deck
products:
  - gateway

# OPTIONAL: Where this solution works
# accepted values: on-prem, konnect
works_on:
  - on-prem
  - konnect

# OPTIONAL: Minimum version requirements for products
# Specify the minimum version where this solution applies
min_version:
  gateway: '3.4'

# OPTIONAL: Related resources that provide additional context
# Each entry should have a text label and a url
related_resources:
  - text: Link text for related documentation
    url: /path/to/related/page/
  - text: Another related resource
    url: /path/to/another/page/

# OPTIONAL: TL;DR section that appears at the top of the article
# Provides a quick question and answer summary
tldr:
  q: What is the question this article answers?
  a: |
    A concise answer that summarizes the solution. This can be 
    multiple lines and supports markdown formatting.

---

## Article content starts here

Write your support article content using standard markdown formatting.

## Use headers to organize sections

Break your content into logical sections with clear headers.

### Include code examples

```bash
# Include relevant commands and code examples
curl -X POST http://localhost:8001/endpoint
```

## Add validation steps

Show users how to verify the solution works correctly.
