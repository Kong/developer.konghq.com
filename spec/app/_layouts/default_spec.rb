# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe 'app/_layouts/default.html' do # rubocop:disable RSpec/DescribeClass
  before { allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance]) }

  let(:site) { JekyllSite.instance }

  let(:page) do
    Jekyll::PageWithoutAFile.new(site, site.source, '', 'index.html').tap do |p|
      p.data['layout'] = 'default'
      p.data['title'] = 'Kong Developer'
      p.data['llm'] = false
      p.data['edit_and_issue_links'] = false
      p.data['get_help'] = false
    end
  end

  def render_default_layout
    layout = site.layouts['default']
    payload = site.site_payload
    payload['page'] = page.data.merge('url' => page.url)
    payload['content'] = '<main>fixture home page</main>'

    info = { registers: { site: site, page: payload['page'] }, strict_filters: true, strict_variables: false }
    context = Liquid::Context.new([payload], {}, info[:registers], true)
    Liquid::Template.parse(layout.content, line_numbers: true).render!(context)
  end

  it 'advertises the security advisories feed with its absolute URL and title' do
    rendered = render_default_layout
    html = Capybara::Node::Simple.new(rendered)
    link = html.find('head link[rel="alternate"][type="application/rss+xml"]', visible: :all)
    expect(link['href']).to eq('https://developer.konghq.com/feeds/security-advisories.xml')
    expect(link['title']).to eq('Kong Security Advisories')
  end
end
