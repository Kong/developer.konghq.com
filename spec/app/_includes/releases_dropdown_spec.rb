# frozen_string_literal: true

RSpec.describe 'releases_dropdown' do
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

  let(:template) do
    <<~LIQUID
      {% include releases_dropdown.html releases_dropdown=dropdown release=page.release %}
    LIQUID
  end

  subject(:html) do
    Capybara::Node::Simple.new(
      render_liquid(template, page: page_data, locals: { 'dropdown' => releases_dropdown })
    )
  end

  def option_values
    html.all('select.releases-dropdown option').map { |option| option[:value] }
  end

  shared_examples 'the AIGW option appended after the release options' do
    it 'appends the AIGW v2 on-prem option after the release options' do
      expect(option_values).to eq([latest_url, old_url, aigw_url])
      expect(html.all('select.releases-dropdown option').last.text.strip).to eq('AIGW v2 on-prem')
    end
  end

  context 'on the latest classic reference page' do
    let(:page_data) do
      { 'url' => latest_url, 'release' => releases.first, 'aigw_onprem_url' => aigw_url }
    end

    include_examples 'the AIGW option appended after the release options'

    it 'selects the latest release option and not the AIGW option' do
      expect(html).to have_css("option[value='#{latest_url}'][selected]")
      expect(html).not_to have_css("option[value='#{aigw_url}'][selected]")
    end
  end

  context 'on a per-release copy' do
    let(:page_data) do
      { 'url' => old_url, 'release' => releases.last, 'aigw_onprem_url' => aigw_url }
    end

    include_examples 'the AIGW option appended after the release options'

    it 'selects the release option matching the page release and not the AIGW option' do
      expect(html).to have_css("option[value='#{old_url}'][selected]")
      expect(html).not_to have_css("option[value='#{aigw_url}'][selected]")
    end
  end

  context 'on the AIGW on-prem reference page' do
    let(:page_data) { { 'url' => aigw_url, 'aigw_onprem_url' => aigw_url } }

    include_examples 'the AIGW option appended after the release options'

    it 'selects the AIGW option and no release option' do
      expect(html).to have_css("option[value='#{aigw_url}'][selected]")
      expect(html).not_to have_css("option[value='#{latest_url}'][selected]")
      expect(html).not_to have_css("option[value='#{old_url}'][selected]")
    end
  end

  context 'when the page does not set aigw_onprem_url' do
    let(:page_data) { { 'url' => '/plugins/other-plugin/reference/', 'release' => releases.first } }

    it 'renders only the release options' do
      expect(option_values).to eq([latest_url, old_url])
      expect(html).not_to have_css('option', text: 'AIGW v2 on-prem')
    end
  end
end
