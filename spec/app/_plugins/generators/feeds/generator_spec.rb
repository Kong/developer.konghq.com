# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::Feeds::Generator do
  before { allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance]) }

  # JekyllSite.instance is a process-global singleton. #run appends a feed page
  # to its pages on each call, so without restoring the list the duplicates
  # leak into every later example that reads site.pages.
  around do |example|
    original_pages = site.pages.dup
    example.run
  ensure
    site.pages.replace(original_pages)
  end

  let(:site) { JekyllSite.instance }
  let(:generator) { described_class.new(site) }

  # Mirrors Jekyll::Renderer: one merged payload with "page" set, so filters
  # like `liquify` (which read @context.environments.first) see `site`.
  def render_page(page)
    payload = site.site_payload
    payload['page'] = page.data.merge('url' => page.url)

    Liquid::Context.new(
      [payload],
      {},
      { site: site, page: payload['page'] },
      true
    ).then { |context| Liquid::Template.parse(page.content).render!(context) }
  end

  describe '#run' do
    # The #run examples need the source to parse every fixture advisory; the
    # fixture collection now only carries dated, valid advisories.
    let!(:pages) { generator.run && site.pages }
    let(:feed) { pages.find { |p| p.url == '/feeds/security-advisories.xml' } }

    it 'publishes the feed at /feeds/security-advisories.xml' do
      expect(feed).not_to be_nil
    end

    it 'marks the page llm: false with no layout' do
      expect(feed.data['llm']).to be(false)
      expect(feed.data['layout']).to be_nil
    end

    it 'renders an atom:link self-href at the feed URL' do
      expect(render_page(feed)).to include(
        '<atom:link href="https://developer.konghq.com/feeds/security-advisories.xml" rel="self" type="application/rss+xml" />'
      )
    end

    it 'excludes every generated feed URL from the sitemap' do
      excluded = site.config.dig('sitemap', 'exclude')
      feed_urls = pages.select { |p| p.url.start_with?('/feeds/') }.map(&:url)
      expect(feed_urls).not_to be_empty
      feed_urls.each { |url| expect(excluded).to include(url) }
    end

    it 'emits pubDate as an absolute UTC timestamp' do
      expect(render_page(feed)).to include('<pubDate>Fri, 05 Jun 2026 00:00:00 +0000</pubDate>')
    end

    it 'resolves site variables in an item title' do
      expect(render_page(feed)).to include('<title>Security Advisory: Kong Gateway Lua sandbox bypass</title>')
    end

    it 'points each item at its advisory as link and permalink guid' do
      rendered = render_page(feed)
      expect(rendered).to include(
        '<link>https://developer.konghq.com/support/security/fixture-lua-sandbox-bypass/</link>'
      )
      expect(rendered).to include(
        '<guid isPermaLink="true">https://developer.konghq.com/support/security/fixture-lua-sandbox-bypass/</guid>'
      )
    end

    it 'carries the configured channel metadata' do
      rendered = render_page(feed)
      expect(rendered).to include('<title>Kong Security Advisories</title>')
      expect(rendered).to include('<description>Security advisories for Kong products.</description>')
      expect(rendered).to include('<link>https://developer.konghq.com/support/security/</link>')
    end

    it 'emits a byte-identical pubDate regardless of the build machine timezone' do
      utc_output = render_page(feed)

      ENV['TZ'] = 'Asia/Tokyo'
      tokyo_output = render_page(feed)
      ENV['TZ'] = 'America/New_York'
      ny_output = render_page(feed)
      ENV['TZ'] = nil

      expect(tokyo_output).to eq(utc_output)
      expect(ny_output).to eq(utc_output)
    end
  end

  describe 'malformed feed configuration' do
    around do |example|
      original_feeds = site.data['feeds']
      example.run
    ensure
      site.data['feeds'] = original_feeds
    end

    it 'fails on an unknown source' do
      site.data['feeds'] = { 'example' => { 'title' => 'Example', 'source' => 'nope' } }
      expect { generator.run }
        .to raise_error(ArgumentError, /feed 'example'.*source 'nope'/i)
    end

    it 'fails on a missing title' do
      allow(Jekyll::Feeds::Sources::SecurityAdvisories).to receive(:items).and_return([])
      site.data['feeds'] = { 'example' => { 'description' => 'No title', 'source' => 'security_advisories' } }
      expect { generator.run }
        .to raise_error(ArgumentError, /feed 'example'.*title/i)
    end

    it 'restores the fixture feeds config after each malformed-config example' do
      expect(site.data['feeds'].keys).to eq(['security-advisories'])
    end
  end
end
