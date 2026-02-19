{% for faq in faqs %}
- {{ faq.q | liquify | lstrip }}{% capture answer %}{{ faq.a | liquify | lstrip }}{% endcapture %}
{{answer | lstrip | indent: 2}}
{% endfor %}