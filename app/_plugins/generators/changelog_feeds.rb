# frozen_string_literal: true

require_relative '../drops/changelog_feed/source_structured'
require_relative '../drops/changelog_feed/source_markdown'

module Jekyll
  # Generates one RSS 2.0 feed per registered changelog source plus one per
  # plugin and a combined plugins feed. Driven by app/_data/feeds.yml. Dates
  # come from app/_data/changelogs/_dates.yml. Entries without a resolved
  # date are skipped (RSS pubDate is required).
  class ChangelogFeedsGenerator < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      registry = site.data['feeds']
      return unless registry

      Array(registry['feeds']).each do |feed_config|
        source = build_source(site, feed_config)
        next unless source && !source.entries.empty?

        site.pages << ChangelogFeedPage.new(site, feed_config, source.entries)
      end

      plugin_cfg = registry['plugin_feeds']
      generate_plugin_feeds(site, plugin_cfg) if plugin_cfg && plugin_cfg['enabled']
    end

    private

    def build_source(site, feed_config)
      case feed_config['source_type']
      when 'structured_gateway'
        Jekyll::Drops::ChangelogFeed::SourceStructured.gateway(site, feed_config)
      when 'markdown'
        Jekyll::Drops::ChangelogFeed::SourceMarkdown.from_config(site, feed_config)
      end
    end

    def generate_plugin_feeds(site, plugin_cfg)
      output_dir = plugin_cfg['output_dir'] || '/feeds/plugins'
      plugin_dirs = Dir.glob(File.join(site.source, '_kong_plugins/*/changelog.json'))

      plugin_dirs.each do |file|
        slug = File.basename(File.dirname(file))
        page_url = "/plugins/#{slug}/changelog/"
        source = Jekyll::Drops::ChangelogFeed::SourceStructured.plugin(
          site, slug, file, page_url
        )
        next if source.entries.empty?

        feed_config = {
          'id'          => "plugin-#{slug}",
          'title'       => "Kong #{slug} plugin changelog",
          'description' => "Release notes for the Kong #{slug} plugin.",
          'page_url'    => page_url,
          'output_path' => "#{output_dir}/#{slug}-changelog.xml"
        }
        site.pages << ChangelogFeedPage.new(site, feed_config, source.entries)
      end
    end
  end

  class ChangelogFeedPage < Jekyll::Page
    def initialize(site, feed_config, feed_entries)
      @site = site
      @base = site.source
      output_path = feed_config['output_path']
      @dir = File.dirname(output_path)
      @basename = File.basename(output_path, '.xml')
      @ext = '.xml'
      @name = "#{@basename}.xml"

      process(@name)

      @data = {
        'layout'           => 'rss',
        'sitemap'          => false,
        'feed_title'       => feed_config['title'],
        'feed_description' => feed_config['description'],
        'feed_url'         => output_path,
        'page_url'         => feed_config['page_url'],
        'feed_entries'     => feed_entries
      }

      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(relative_path, :page, key)
      end
    end

    def url_placeholders
      { path: @dir, basename: basename, output_ext: output_ext }
    end
  end
end
