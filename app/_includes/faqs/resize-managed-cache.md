{% if include.section == "question" %}

Can I change the size of my managed cache after I've created it?
{% elsif include.section == "answer" %}

You can only upgrade the size of a managed cache, you can't downsize one. 
If you want to downsize a cache, you must delete and recreate it.

For more information about managed cache sizing recommendations and how to resize a managed cache, see [Managed cache for Redis](/dedicated-cloud-gateways/managed-cache/).

{% endif %}