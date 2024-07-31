---
title: Rate Limiting

faqs:
  - q: Does it do X?
    a: Yes, it does X!
  - q: How about Y?
    a: Did I mention it does X?
  - q: And Z?
    a: |
      Yes, Z is the best, much better than Y.

      Oscillation within a space time matrix, with respect to quantum intersection matrices, interwoven on a molecular level with geodesic lattice structures to elicit a persistent linkage between subordinate levels of abstraction.
tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform
---

Rate limit how many HTTP requests can be made in a given period of seconds, minutes, hours, days,
months, or years. If the underlying service or route has no authentication layer, the Client IP address is
used. Otherwise, the consumer is used if an authentication plugin has been configured


{% contentfor config_examples %}
{% entity_example %}
type: plugin
data:
  name: rate-limiting
  config:
    second: 5
    hour: 1000
    policy: local
targets:
  - consumer
  - service
  - route
  - global
  - consumer_group
{% endentity_example %}
{% endcontentfor %}
