# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::AIGatewayPluginPages::Pages::Reference do
  let(:plugin) do
    instance_double(
      Jekyll::AIGatewayPluginPages::Plugin,
      slug: 'ai-proxy-advanced',
      metadata: { 'title' => 'AI Proxy Advanced', 'faqs' => [] },
      schema: { 'properties' => { 'config' => {} } },
      icon: nil
    )
  end

  let(:page) { described_class.new(plugin:, file: 'app/_ai_gateway_plugins/ai-proxy-advanced/reference.md') }

  describe '.url' do
    it { expect(described_class.url(plugin)).to eq('/ai-gateway/on-prem/plugins/ai-proxy-advanced/reference/') }
  end

  describe '#layout' do
    it { expect(page.layout).to eq('ai_gateway_policies/reference') }
  end

  describe '#content' do
    it { expect(page.content).to eq('') }
  end

  describe '#data' do
    subject(:data) { page.data }

    it { expect(data['content_type']).to eq('reference') }
    it { expect(data['reference?']).to be(true) }
    it { expect(data['toc']).to be(false) }
    it { expect(data['versioned']).to be(false) }
    it { expect(data['schema']).to eq({ 'properties' => { 'config' => {} } }) }
    it { expect(data['overview_url']).to eq('/ai-gateway/on-prem/plugins/ai-proxy-advanced/') }
    it { expect(data).not_to have_key('faqs') }
  end
end
