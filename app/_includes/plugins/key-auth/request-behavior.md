The following table describes how {{site.base_gateway}} behaves in various authentication scenarios:

{% table %}
columns:
  - title: Condition
    key: condition
  - title: "Proxied to upstream service?"
    key: proxy
  - title: Response code
    key: response
rows:
  - condition: "The request has a valid API key."
    proxy: Yes
    response: 200
  - condition: "No API key is provided."
    proxy: No
    response: 401
  - condition: "The API key is not known to {{site.base_gateway}}"
    proxy: No
    response: 401
  - condition: "A runtime error occurred."
    proxy: No
    response: 500
{% endtable %}
