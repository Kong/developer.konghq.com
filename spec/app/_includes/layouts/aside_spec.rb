# frozen_string_literal: true

# `aside.html` renders the version dropdown for versioned pages and for the
# unversioned AIGW on-prem page; the ifhascontent/contentblock tags come from
# jekyll-contentblocks, which Jekyll loads from the :jekyll_plugins group.
require 'jekyll-contentblocks'

RSpec.describe 'layouts/aside version dropdown' do
  let(:aigw_url) { '/plugins/fixture-auth/ai-gateway/v2/on-prem/reference/' }
  let(:latest_url) { '/plugins/fixture-auth/reference/' }
  let(:old_url) { '/plugins/fixture-auth/reference/3.9/' }

  let(:releases) do
    [
      Jekyll::Drops::Release.new({ 'release' => '3.10', 'latest' => true }),
      Jekyll::Drops::Release.new({ 'release' => '3.9' })
    ]
  end

  let(:releases_dropdown) do
    Jekyll::Drops::ReleasesDropdown.new(base_url: latest_url, releases:)
  end

  let(:rendered) do
    render_liquid('{% include layouts/aside.html %}', page: page_data, locals: {})
  end

  subject(:html) { Capybara::Node::Simple.new(rendered) }

  context 'on the unversioned AIGW on-prem reference page' do
    let(:page_data) do
      {
        'url' => aigw_url,
        'releases_dropdown' => releases_dropdown,
        'aigw_onprem_url' => aigw_url,
        'aigw_onprem_plugin_reference?' => true
      }
    end

    it 'renders the version dropdown' do
      expect(html).to have_css('select.releases-dropdown')
    end

    it 'renders the release options plus the selected AIGW option' do
      expect(html).to have_css("option[value='#{latest_url}']")
      expect(html).to have_css("option[value='#{old_url}']")
      expect(html).to have_css("option[value='#{aigw_url}'][selected]")
    end

    it 'selects no release option' do
      expect(html).not_to have_css("option[value='#{latest_url}'][selected]")
      expect(html).not_to have_css("option[value='#{old_url}'][selected]")
    end

    # The release options compare against this page's nil release, so a
    # nil-unsafe comparison renders `Liquid error: internal` into the markup.
    it 'renders the release options without a Liquid error marker' do
      expect(rendered).not_to include('Liquid error')
    end
  end

  context 'on a versioned page' do
    let(:page_data) do
      { 'url' => latest_url, 'releases_dropdown' => releases_dropdown, 'versioned' => true,
        'release' => releases.first }
    end

    it 'renders the dropdown with the matching release selected' do
      expect(html).to have_css('select.releases-dropdown')
      expect(html).to have_css("option[value='#{latest_url}'][selected]")
    end

    it 'renders no AIGW option' do
      expect(html).not_to have_css('option', text: 'AIGW v2 on-prem')
    end
  end

  context 'on an unversioned page without the AIGW flag' do
    let(:page_data) { { 'url' => '/plugins/fixture-auth/changelog/', 'releases_dropdown' => releases_dropdown } }

    it 'renders no dropdown' do
      expect(html).not_to have_css('select.releases-dropdown')
    end
  end

  context 'without a dropdown' do
    let(:page_data) { { 'url' => '/plugins/fixture-auth/changelog/', 'versioned' => true } }

    it 'renders no dropdown' do
      expect(html).not_to have_css('select.releases-dropdown')
    end
  end
end
