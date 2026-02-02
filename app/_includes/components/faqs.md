{% for faq in faqs %}
- {{ faq.q | liquify }}{% capture answer %}{{ faq.a | liquify }}{% endcapture %}
{{answer | indent: 2}}
{% endfor %}