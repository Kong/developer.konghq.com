{% if include.section == "question" %}

How can I share {{include.feature}}s with other {{site.konnect_short_name}} users and teams?

{% elsif include.section == "answer" %}

Navigate to the {{include.feature}} in {{site.observability}}, click the action menu, and select "Share". 
You can add users and teams to share the {{include.feature}} with them and configure their level of access (view only, edit, or admin).

{% endif %}