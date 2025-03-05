---
content_type: reference
no_version: true
---

## Changelog

### {{site.base_gateway}} 2.8.x

* Use response buffering from the PDK.
* If plugin has no output, it will now return the raw body instead of attempting
to restore the original response body.