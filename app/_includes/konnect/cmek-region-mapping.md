The following table describes which AWS regions map to each {{site.konnect_short_name}} geo:

<!--vale off-->
{% table %}
columns:
  - title: "{{site.konnect_short_name}} geo"
    key: geo
  - title: AWS region
    key: aws
rows:
  - geo: "AU (Australia)"
    aws: |
        * ap-southeast-2
        * ap-southeast-4
  - geo: "EU (Europe)"
    aws: |
        * eu-central-1
        * eu-west-1
  - geo: "ME (Middle East)"
    aws: |
        * me-central-1
        * me-south-1
  - geo: "US (United States)"
    aws: |
        * us-west-2
        * us-east-2
  - geo: "IN (India)"
    aws: |
        * ap-south-1
        * ap-south-2
  - geo: "SG (Singapore) (beta)"
    aws: |
        * ap-southeast-1

{% endtable %}
<!--vale on-->