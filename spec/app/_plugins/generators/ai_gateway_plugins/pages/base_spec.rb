# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::AIGatewayPluginPages::Pages::Base do
  let(:plugin) do
    instance_double(
      Jekyll::AIGatewayPluginPages::Plugin,
      slug: 'ai-proxy-advanced',
      metadata: { 'title' => 'AI Proxy Advanced' },
      schema: { 'properties' => { 'config' => {} } },
      icon: 'ai-proxy-advanced.png'
    )
  end

  let(:page) { described_class.new(plugin:, file: 'app/_ai_gateway_plugins/ai-proxy-advanced/index.md') }

  describe '#data' do
    subject(:data) { page.data }

    before { allow(page).to receive(:layout).and_return('policies/with_aside') }

    it { expect(data['slug']).to eq('ai-proxy-advanced') }
    it { expect(data['breadcrumbs']).to eq(['/ai-gateway/', '/ai-gateway/on-prem/', '/ai-gateway/on-prem/plugins/']) }
    it { expect(data['has_overview?']).to be(true) }
    it { expect(data['plugin?']).to be(true) }
    it { expect(data['schema']).to eq({ 'properties' => { 'config' => {} } }) }
    it { expect(data['overview_url']).to eq('/ai-gateway/on-prem/plugins/ai-proxy-advanced/') }
    it { expect(data['reference_url']).to eq('/ai-gateway/on-prem/plugins/ai-proxy-advanced/reference/') }
    it { expect(data['icon']).to eq('/assets/icons/plugins/ai-proxy-advanced.png') }

    context 'when plugin has no icon' do
      before { allow(plugin).to receive(:icon).and_return(nil) }

      it { expect(data['icon']).to be_nil }
    end
  end
end
