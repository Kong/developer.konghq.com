# frozen_string_literal: true

RSpec.describe Jekyll::ControlPlaneRequest do
  let(:url_origin) do
    { 'konnect' => 'https://konnect.example.com', 'on_prem' => 'https://on-prem.example.com' }
  end
  let(:site_data) { { 'control_plane_request' => { 'url_origin' => url_origin } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:page) do
    { 'output_format' => 'html', 'path' => 'test.md', 'products' => ['gateway'], 'works_on' => works_on }
  end
  let(:template) do
    <<~LIQUID
      {% control_plane_request %}
      url: /services
      method: GET
      {% endcontrol_plane_request %}
    LIQUID
  end

  subject(:rendered) { render_liquid(template, page: page) }

  let(:html) { Capybara::Node::Simple.new(rendered) }

  describe 'html output' do
    include_examples 'a dual-topology content div'
    include_examples 'a section-aware dual-topology content div'
  end

  describe 'markdown output_format' do
    let(:page) do
      { 'output_format' => 'markdown', 'path' => 'test.md', 'products' => ['gateway'], 'works_on' => works_on }
    end

    context 'works_on: konnect' do
      let(:works_on) { %w[konnect] }

      it 'renders no wrapping div' do
        expect(rendered).not_to include('<div')
      end

      it 'renders the konnect snippet' do
        expect(rendered).to include('https://konnect.example.com/services')
      end
    end

    context 'works_on: on-prem' do
      let(:works_on) { %w[on-prem] }

      it 'renders the on-prem snippet' do
        expect(rendered).to include('https://on-prem.example.com/services')
      end
    end

    context 'works_on: konnect and on-prem' do
      let(:works_on) { %w[konnect on-prem] }

      it 'renders both snippets' do
        expect(rendered).to include('https://konnect.example.com/services')
        expect(rendered).to include('https://on-prem.example.com/services')
      end
    end
  end

  describe 'yaml validation' do
    let(:works_on) { %w[konnect] }

    context 'missing url' do
      let(:template) do
        <<~LIQUID
          {% control_plane_request %}
          method: GET
          {% endcontrol_plane_request %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'Missing `url` in {% control_plane_request %}.')
      end
    end

    include_examples 'a block that rejects malformed yaml', 'control_plane_request'
  end
end
