---
title: Rate Limiting
---

Rate limit how many HTTP requests can be made in a given period of seconds, minutes, hours, days,
months, or years. If the underlying service or route has no authentication layer, the Client IP address is
used. Otherwise, the consumer is used if an authentication plugin has been configured.
