{% if include.section == "question" %}

Can I change the size of my managed cache after I've created it?
{% elsif include.section == "answer" %}

Yes, you can upgrade the size of a managed cache, but you can't downsize a cache. 
If you need a smaller cache, delete the existing cache and create a new one.

For more information about managed cache sizing recommendations and how to resize a managed cache, see [Managed cache for Redis](/dedicated-cloud-gateways/managed-cache/).

{% endif %}