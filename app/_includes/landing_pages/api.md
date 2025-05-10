{% assign api = site.data.ssg_api_pages | where_exp: "page", "page.title == include.config.title" | first %}

{% include card.html title=api.title description=api.description cta_text='See reference' cta_url=api.url %}