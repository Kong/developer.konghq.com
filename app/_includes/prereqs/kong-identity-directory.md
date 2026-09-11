A directory is a regional collection of principals. 
A {{site.konnect_short_name}} organization supports only one {{site.identity}} directory. Create a directory for the tutorial, or look up your existing one.

{% navtabs 'directory' %}
{% navtab "Create directory" %}

Create a directory for this tutorial:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "kong-identity-directory"
  description: "Directory for this tutorial"
  allow_all_control_planes: true
capture:
  - variable: DIRECTORY_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> If you run into 403 errors when trying to create a directory, the directory likely already exists. Look up your existing directory instead.

{% endnavtab %}
{% navtab "Look up directory" %}
Look up an existing directory:
<!--vale off-->
{% konnect_api_request %}
url: /v2/directories
status_code: 200
method: GET
capture:
  - variable: DIRECTORY_ID
    jq: ".data[0].id"
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% endnavtabs %}
