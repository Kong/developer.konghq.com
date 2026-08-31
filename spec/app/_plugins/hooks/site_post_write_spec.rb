# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LlmsTxtWriter do
  let(:site_data) do
    {
      'products' => {
        'gateway' => { 'name' => 'Kong Gateway' },
        'ai-gateway' => { 'name' => 'AI Gateway' },
        'konnect' => { 'name' => 'Konnect' }
      },
      'tools' => { 'deck' => { 'name' => 'decK' } }
    }
  end
  let(:all_pages) { [] }

  let(:site) do
    instance_double(Jekyll::Site, dest: '/fake/dest', data: site_data).tap do |s|
      allow(s).to receive(:config).and_return(
        'markdown_pages_to_render' => all_pages,
        'liquid' => { 'strict_filters' => false, 'strict_variables' => false }
      )
      allow(s).to receive(:site_payload).and_return(
        'site' => { 'links' => { 'web' => 'https://developer.konghq.com' } }
      )
    end
  end

  let(:writer) { described_class.new(site) }

  describe '#pages' do
    context 'when a page has canonical? == false' do
      let(:all_pages) do
        [
          build_page(url: '/visible/', data: {}),
          build_page(url: '/not-canonical/', data: { 'canonical?' => false })
        ]
      end

      it 'excludes that page' do
        expect(writer.pages.map(&:url)).to contain_exactly('/visible/')
      end
    end

    context 'when canonical? is nil' do
      let(:all_pages) { [build_page(url: '/nil-canonical/', data: { 'canonical?' => nil })] }

      it 'includes the page' do
        expect(writer.pages.map(&:url)).to include('/nil-canonical/')
      end
    end

    context 'with multiple pages in unsorted order' do
      let(:all_pages) { [build_page(url: '/b/'), build_page(url: '/a/')] }

      it 'returns pages sorted by URL' do
        expect(writer.pages.map(&:url)).to eq(['/a/', '/b/'])
      end
    end
  end

  describe '#api_pages' do
    let(:by_content_type) { build_page(url: '/api/konnect/dev-portal/v2/', data: { 'content_type' => 'api' }) }
    let(:by_layout)       { build_page(url: '/api/konnect/dev-portal/v2/errors/', data: { 'layout' => 'api/errors' }) }
    let(:other)           { build_page(url: '/other/', data: { 'content_type' => 'reference' }) }
    let(:all_pages)       { [by_content_type, by_layout, other] }

    it 'selects pages with content_type api' do
      expect(writer.api_pages).to include(by_content_type)
    end

    it 'selects pages with layout api/errors' do
      expect(writer.api_pages).to include(by_layout)
    end

    it 'excludes other pages' do
      expect(writer.api_pages).not_to include(other)
    end
  end

  describe '#plugin_pages' do
    let(:gateway_plugin) { build_page(url: '/plugins/acme/', data: { 'plugin?' => true, 'products' => ['gateway'] }) }
    let(:aigw_policy)    do
      build_page(url: '/ai-gateway/policies/acme/', data: { 'plugin?' => true, 'products' => ['ai-gateway'] })
    end
    let(:non_plugin)     { build_page(url: '/gateway/', data: { 'products' => ['gateway'] }) }
    let(:all_pages)      { [gateway_plugin, aigw_policy, non_plugin] }

    it 'selects only gateway plugins' do
      expect(writer.plugin_pages).to contain_exactly(gateway_plugin)
    end
  end

  describe '#ai_gateway_policy_pages' do
    let(:aigw_only) do
      build_page(url: '/ai-gateway/policies/acme/', data: { 'plugin?' => true, 'products' => ['ai-gateway'] })
    end
    let(:aigw_and_gw) do
      build_page(url: '/plugins/ai-proxy/', data: { 'plugin?' => true, 'products' => %w[gateway ai-gateway] })
    end
    let(:gateway_only) { build_page(url: '/plugins/acme/', data: { 'plugin?' => true, 'products' => ['gateway'] }) }
    let(:all_pages)    { [aigw_only, aigw_and_gw, gateway_only] }

    it 'selects only pages whose products is exactly ["ai-gateway"]' do
      expect(writer.ai_gateway_policy_pages).to contain_exactly(aigw_only)
    end
  end

  describe '#how_to_pages' do
    let(:how_to) { build_page(url: '/how-to/get-started/', data: { 'content_type' => 'how_to' }) }
    let(:other)  { build_page(url: '/other/', data: { 'content_type' => 'reference' }) }
    let(:all_pages) { [how_to, other] }

    it { expect(writer.how_to_pages).to contain_exactly(how_to) }
  end

  describe '#cookbook_pages' do
    let(:cookbook) { build_page(url: '/cookbooks/mock/', data: { 'content_type' => 'cookbook' }) }
    let(:other)    { build_page(url: '/other/', data: { 'content_type' => 'reference' }) }
    let(:all_pages) { [cookbook, other] }

    it { expect(writer.cookbook_pages).to contain_exactly(cookbook) }
  end

  describe '#docs' do
    context 'with pages from different products' do
      let(:gw_page)      { build_page(url: '/gateway/foo/', data: { 'products' => ['gateway'] }) }
      let(:konnect_page) { build_page(url: '/konnect/bar/', data: { 'products' => ['konnect'] }) }
      let(:aigw_page) { build_page(url: '/ai-gateway/baz/', data: { 'products' => ['ai-gateway'] }) }

      let(:all_pages) { [gw_page, konnect_page, aigw_page] }

      it 'groups pages by product and sorts groups alphabetically by resolved name' do
        expect(writer.docs.map { |g| g['name'] }).to eq(['AI Gateway', 'Kong Gateway', 'Konnect'])
      end
    end

    context 'when a page has a tool but no product' do
      let(:page)      { build_page(url: '/deck/foo/', data: { 'tools' => ['deck'] }) }
      let(:all_pages) { [page] }

      it 'groups the page under the resolved tool name' do
        group = writer.docs.find { |g| g['name'] == 'decK' }
        expect(group&.dig('pages')).to include(page)
      end
    end

    context 'when a page has no product or tool' do
      let(:page)      { build_page(url: '/misc/', data: {}) }
      let(:all_pages) { [page] }

      it 'places the page in an Other group sorted last' do
        expect(writer.docs.last['name']).to eq('Other')
        expect(writer.docs.last['pages']).to include(page)
      end
    end
  end

  describe '#resolve_name' do
    it { expect(writer.resolve_name('gateway')).to eq('Kong Gateway') }
    it { expect(writer.resolve_name('deck')).to eq('decK') }
  end
end
