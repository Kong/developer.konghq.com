{% assign topics = "" %}
{% assign products = "" %}

{% for item in include.config %}
{% assign topics = topics | append: "," | append: item.topic %}
{% assign products = products | append: "," | append: item.product %}
{% endfor %}

{% assign topics = topics | remove_first: "," | split: "," | uniq %}
{% assign products = products | remove_first: "," | split: "," | uniq %}

{% assign topics_exp = topics | join: "' or tutorial.topics contains '" | prepend: "tutorial.topics contains '" | append: "'" %}
{% assign products_exp = products | join: "' or tutorial.products contains '" | prepend: "tutorial.products contains '" | append: "'" %}

{% assign full_exp = topics_exp | append: " and " | append: products_exp %}

<ul>
  {% assign tutorial_list = site.tutorials %}
  {% assign tutorials = tutorial_list | where_exp: "tutorial", full_exp %}

  {% for tutorial in tutorials %}
    <li>
      <a href="{{ tutorial.url }}">{{ tutorial.title }}</a>
    </li>
  {% endfor %}

</ul>