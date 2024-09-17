{% assign summary='Kong Gateway running' %}
{% capture details_content %}
  This tutorial requires Kong Gateway. 
  If you don't have it set up yet, you can use the [quickstart script](https://get.konghq.com/quickstart) to get an instance of Kong Gateway running almost instantly:

```bash
curl -Ls https://get.konghq.com/quickstart | bash -s
```
Once Kong Gateway is ready, you will see the following message:
```bash
Kong Gateway Ready
```
{:.no-copy-code}
{% endcapture %}


{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content %}