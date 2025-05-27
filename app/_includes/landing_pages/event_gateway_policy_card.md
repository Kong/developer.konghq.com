{% assign policy_id = include.config.policy %}

{% assign policies_list = site.event_gateway_policies %}
{% assign policy = policies_list | where_exp: "policy", "policy.slug == policy_id" | first %}
{% assign url = policy.url | append: include.config.additional_url %}

{% include card.html title=policy.title description=policy.description cta_text='See reference' cta_url=url icon=policy.icon %}