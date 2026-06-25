# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LlmsTxtWriter, 'template rendering' do
  let(:web_base)   { 'https://developer.konghq.com' }
  let(:all_pages)  { [] }
  let(:site_data) do
    {
      'products' => {
        'gateway' => { 'name' => 'Kong Gateway' },
        'ai-gateway' => { 'name' => 'AI Gateway' }
      },
      'tools' => {}
    }
  end

  let(:site) do
    instance_double(Jekyll::Site, dest: '/fake/dest', data: site_data).tap do |s|
      allow(s).to receive(:config).and_return(
        'markdown_pages_to_render' => all_pages,
        'liquid' => { 'strict_filters' => false, 'strict_variables' => false }
      )
      allow(s).to receive(:site_payload).and_return(
        'site' => { 'links' => { 'web' => web_base } }
      )
    end
  end

  let(:rendered) do
    captured = nil
    allow(File).to receive(:write).with(File.join('/fake/dest', 'llms.txt'), anything) do |_, content|
      captured = content
    end
    described_class.process(site)
    captured
  end

  # Returns the body of a named ## section, up to (but not including) the next ##.
  def section(output, name)
    output[/^## #{Regexp.escape(name)}\n(.*?)(?=^## |\z)/m, 1] || ''
  end

  context 'with an API page' do
    let(:all_pages) do
      [build_page(url: '/api/foo/', llm_title: 'Foo API', description: 'Foo API description',
                  data: { 'content_type' => 'api' })]
    end

    it 'renders the page inside the API Reference section' do
      expect(section(rendered, 'API Reference')).to include(
        '[Foo API](https://developer.konghq.com/api/foo/): Foo API description'
      )
    end
  end

  context 'with a how-to page' do
    let(:all_pages) do
      [build_page(url: '/how-to/foo/', llm_title: 'How to Foo', description: 'Do foo.',
                  data: { 'content_type' => 'how_to' })]
    end

    it 'renders the page inside the How-To Guides section' do
      expect(section(rendered, 'How-To Guides')).to include(
        '[How to Foo](https://developer.konghq.com/how-to/foo/): Do foo.'
      )
    end
  end

  context 'with a cookbook page' do
    let(:all_pages) do
      [build_page(url: '/cookbook/bar/', llm_title: 'Bar Cookbook', description: 'Bar recipe.',
                  data: { 'content_type' => 'cookbook' })]
    end

    it 'renders the page inside the Cookbooks section' do
      expect(section(rendered, 'Cookbooks')).to include(
        '[Bar Cookbook](https://developer.konghq.com/cookbook/bar/): Bar recipe.'
      )
    end
  end

  context 'with a gateway plugin page' do
    let(:all_pages) do
      [build_page(url: '/plugins/my-plugin/', llm_title: 'My Plugin', description: 'A plugin.',
                  data: { 'plugin?' => true, 'products' => ['gateway'] })]
    end

    it 'renders the page inside the API Gateway Plugins section' do
      expect(section(rendered, 'API Gateway Plugins')).to include(
        '[My Plugin](https://developer.konghq.com/plugins/my-plugin/): A plugin.'
      )
    end
  end

  context 'with an AI Gateway policy page' do
    let(:all_pages) do
      [build_page(url: '/ai-gateway/policies/my-policy/', llm_title: 'My Policy', description: 'A policy.',
                  data: { 'plugin?' => true, 'products' => ['ai-gateway'] })]
    end

    it 'renders the page inside the AI Gateway Policies section' do
      expect(section(rendered, 'AI Gateway Policies')).to include(
        '[My Policy](https://developer.konghq.com/ai-gateway/policies/my-policy/): A policy.'
      )
    end
  end

  context 'with a regular doc page' do
    let(:all_pages) do
      [build_page(url: '/gateway/install/', llm_title: 'Install Gateway', description: 'Install it.',
                  data: { 'products' => ['gateway'] })]
    end

    it 'renders the page inside the product section' do
      expect(section(rendered, 'Kong Gateway')).to include(
        '[Install Gateway](https://developer.konghq.com/gateway/install/)'
      )
    end
  end

  context 'with a non-canonical page alongside a canonical one' do
    let(:all_pages) do
      [
        build_page(url: '/a/', llm_title: 'Visible', description: 'Shown.',
                   data: { 'content_type' => 'how_to' }),
        build_page(url: '/b/', llm_title: 'Hidden',  description: 'Not shown.',
                   data: { 'content_type' => 'how_to', 'canonical?' => false })
      ]
    end

    it 'includes the canonical page and omits the non-canonical one' do
      how_to = section(rendered, 'How-To Guides')
      expect(how_to).to include('Visible')
      expect(how_to).not_to include('Hidden')
    end
  end

  context 'with a doc page that has no description' do
    let(:all_pages) do
      [build_page(url: '/gateway/foo/', llm_title: 'No Desc', description: nil,
                  data: { 'products' => ['gateway'] })]
    end

    it 'renders the link without a colon separator' do
      gw = section(rendered, 'Kong Gateway')
      expect(gw).to include('[No Desc](https://developer.konghq.com/gateway/foo/)')
      expect(gw).not_to include('[No Desc](https://developer.konghq.com/gateway/foo/):')
    end
  end
end
