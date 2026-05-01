{% assign releases = site.data.products.mesh.releases %}
{% table %}
columns:
  - title: Version
    key: version
  - title: Latest Patch
    key: patch
  - title: Released Date
    key: releaseDate
  - title: End of Full Support
    key: eol
rows:
{% for release in releases reversed %}
  - version: "{{release.release}}.x{% if release.lts %} (LTS){% endif %}"
    patch: "{{release.version}}"
    releaseDate: "{{release.releaseDate}}"
    eol: "{{release.eol}}"
{% endfor %}
{% endtable %}
