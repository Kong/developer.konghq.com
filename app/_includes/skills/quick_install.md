```bash
npx skills@latest add {{site.repos.skills | remove: "https://github.com/" | remove_last: "/"}}{% if include.slug%} --skill {{ include.slug }}{% endif %}
```