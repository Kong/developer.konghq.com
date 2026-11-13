# RSS feeds

The site publishes RSS feeds at `/feeds/<name>.xml`. The first feed is `/feeds/security-advisories.xml`. Every documentation page advertises the feeds in its `<head>` with a `<link rel="alternate" type="application/rss+xml">` element, so feed readers can discover them automatically.

## How it works

- `app/_data/feeds.yml` lists the feeds. Each entry has a `title`, `description`, `link` (the HTML page the feed belongs to), and `source`.
- Each `source` is a Ruby class in `app/_plugins/generators/feeds/sources/`. It returns a list of items, each with a `title`, `url`, and a `date`.
- `app/_plugins/generators/feeds/generator.rb` builds one page per entry and renders it with `app/_includes/feeds/rss.xml`.

Titles go through `liquify`, so `{{site.*}}` variables in a title work.

## Add a feed

1. Add an entry to `app/_data/feeds.yml`.
2. Add a source class with an `items(site)` class method. Return plain hashes with `title`, `url`, and `date` as a `Time`. Sort them newest first.
3. Register the class in the `SOURCES` hash in `generator.rb`. An unknown `source` fails the build with an error.
4. Add a spec in `spec/app/_plugins/generators/feeds/`.
5. Run `make run`, then check the feed:

```bash
curl -s http://localhost:8888/feeds/<name>.xml | xmllint --noout -
```

## Next sources

The Gateway versions (`SupportedVersionAPI` in `app/_plugins/hooks/site_post_write.rb`) and the changelog JSON files (`app/_changelogs/*.json`, read in `app/_plugins/drops/gateway_changelog.rb`) are the likely next sources.
