# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::AIGatewayPluginPages::Generator do
  let(:pages) { [] }
  let(:site) do
    instance_double(
      Jekyll::Site,
      source: '/app',
      config: {},
      data: { 'ai_gateway_plugins' => {} },
      pages:
    )
  end

  describe '#run' do
    context 'when skipped' do
      let(:site) do
        instance_double(
          Jekyll::Site,
          source: '/app',
          config: { 'skip' => { 'ai_gateway_plugins' => true } },
          data: { 'ai_gateway_plugins' => {} },
          pages:
        )
      end

      it 'generates no pages' do
        allow(Dir).to receive(:glob)
        described_class.new(site).run
        expect(pages).to be_empty
      end
    end

    context 'when not skipped' do
      let(:folder) { '/app/_ai_gateway_plugins/ai-proxy-advanced/' }
      let(:jekyll_page) { instance_double(Jekyll::Page) }
      let(:plugin) do
        instance_double(
          Jekyll::AIGatewayPluginPages::Plugin,
          slug: 'ai-proxy-advanced',
          folder:
        )
      end

      before do
        allow(Dir).to receive(:glob).and_return([folder])
        allow(Jekyll::AIGatewayPluginPages::Plugin).to receive(:new)
          .with(folder:, slug: 'ai-proxy-advanced')
          .and_return(plugin)
        allow(Jekyll::AIGatewayPluginPages::Pages::Overview).to receive(:new).and_return(
          instance_double(Jekyll::AIGatewayPluginPages::Pages::Overview, to_jekyll_page: jekyll_page)
        )
        allow(Jekyll::AIGatewayPluginPages::Pages::Reference).to receive(:new).and_return(
          instance_double(Jekyll::AIGatewayPluginPages::Pages::Reference, to_jekyll_page: jekyll_page)
        )
      end

      it 'generates an overview and reference page per plugin' do
        described_class.new(site).run
        expect(pages.size).to eq(2)
      end

      it 'registers the overview page in site.data' do
        described_class.new(site).run
        expect(site.data['ai_gateway_plugins']['ai-proxy-advanced']).to eq(jekyll_page)
      end
    end
  end
end
