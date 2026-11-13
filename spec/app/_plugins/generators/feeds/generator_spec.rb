# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::Feeds::Generator do
  before { allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance]) }

  let(:site) { JekyllSite.instance }
  let(:generator) { described_class.new(site) }

  def render_page(page)
    context = Liquid::Context.new(
      [{ 'page' => page.data.merge('url' => page.url) }, site.site_payload],
      {},
      { site: site, page: page.data },
      true
    )
    Liquid::Template.parse(page.content).render!(context)
  end

  describe '#run' do
    let!(:pages) { generator.run && site.pages }

    it 'publishes the feed at /feeds/security-advisories.xml' do
      feed = pages.find { |p| p.url == '/feeds/security-advisories.xml' }
      expect(feed).not_to be_nil
    end

    it 'marks the page llm: false with no layout' do
      feed = pages.find { |p| p.url == '/feeds/security-advisories.xml' }
      expect(feed.data['llm']).to be(false)
      expect(feed.data['layout']).to be_nil
    end

    it 'renders an atom:link self-href at the feed URL' do
      feed = pages.find { |p| p.url == '/feeds/security-advisories.xml' }
      rendered = render_page(feed)
      expect(rendered).to include(
        '<atom:link href="https://developer.konghq.com/feeds/security-advisories.xml" rel="self" type="application/rss+xml" />'
      )
    end
  end
end
