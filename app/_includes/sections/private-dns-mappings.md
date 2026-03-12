The following table describes how DNS is mapped:

{% table %}
columns:
  - title: Mapping type
    key: type
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - type: 1-to-1 mapping
    description: Each domain is mapped to a unique IP address.
    example: "`example.com` → `192.168.1.1`"
  - type: N-to-1 mapping
    description: Multiple domains share the same IP address.
    example: "`example.com`, `example2.com` → `192.168.1.1`"
  - type: M-to-N mapping
    description: Multiple domains are mapped to multiple IP addresses, without a strict one-to-one relationship.
    example: >-
      `example.com` → `192.168.1.2`
      <br><br>
      `example3.com` → `192.168.1.1`
{% endtable %}