---
content_type: reference
---

## Changelog

### {{site.base_gateway}} 3.10.x
* Fixed an issue where jq did not work properly with the Proxy Cache Advanced plugin.

### {{site.base_gateway}} 2.8.x

* Use response buffering from the PDK.
* If plugin has no output, it will now return the raw body instead of attempting
to restore the original response body.