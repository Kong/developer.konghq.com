# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::AIGatewayPluginPages::Pages::Overview do
  let(:plugin) do
    instance_double(
      Jekyll::AIGatewayPluginPages::Plugin,
      slug: 'ai-proxy-advanced',
      metadata: { 'title' => 'AI Proxy Advanced' },
      schema: { 'properties' => { 'config' => {} } },
      icon: nil
    )
  end

  let(:file) { 'app/_ai_gateway_plugins/ai-proxy-advanced/index.md' }
  let(:page) { described_class.new(plugin:, file:) }

  describe '.url' do
    it { expect(described_class.url(plugin)).to eq('/ai-gateway/on-prem/plugins/ai-proxy-advanced/') }
  end

  describe '#layout' do
    it { expect(page.layout).to eq('policies/with_aside') }
  end

  describe '#content' do
    it 'returns the body of the index.md file' do
      allow(File).to receive(:read).with(file).and_return("---\ntitle: AI Proxy Advanced\n---\nSome content")
      expect(page.content).to eq('Some content')
    end
  end

  describe '#data' do
    subject(:data) { page.data }

    before { allow(File).to receive(:read).with(file).and_return("---\ntitle: AI Proxy Advanced\n---\n") }

    it { expect(data['overview?']).to be(true) }
    it { expect(data['overview_url']).to eq('/ai-gateway/on-prem/plugins/ai-proxy-advanced/') }
    it { expect(data['breadcrumbs']).to eq(['/ai-gateway/', '/ai-gateway/on-prem/', '/ai-gateway/on-prem/plugins/']) }
  end
end
