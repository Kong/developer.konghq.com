{% if include.type=="question" %}
Can I configure Vault in a different way without using the Vault entity directly?
{% endif %}

{% if include.type=="answer" %}
Yes, you can also configure a Vault in one of the following ways:
* Using environment variables, set at {{site.base_gateway}} startup
* Using parameters in `kong.conf`, set at {{site.base_gateway}} startup

See the [Vault reference for your provider](/gateway/entities/vault/#vault-provider-specific-configuration-parameters) for the available parameters and their format in each method.
{% endif %}