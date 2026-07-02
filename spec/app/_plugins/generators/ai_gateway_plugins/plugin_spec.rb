# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::AIGatewayPluginPages::Plugin do
  let(:folder) { 'app/_ai_gateway_plugins/ai-proxy-advanced' }
  let(:plugin) { described_class.new(folder:, slug: 'ai-proxy-advanced') }

  describe '#schema' do
    it 'returns an AIGWPolicySchema instance' do
      expect(plugin.schema).to be_a(Jekyll::Drops::Plugins::AIGWPolicySchema)
    end
  end

  describe '#name' do
    before do
      allow(File).to receive(:read)
        .with(File.join(folder, 'index.md'))
        .and_return("---\nname: 'AI Proxy Advanced'\ntitle: 'AI Proxy Advanced'\n---\n")
    end

    it { expect(plugin.name).to eq('AI Proxy Advanced') }
  end

  describe '#icon' do
    before do
      allow(File).to receive(:read)
        .with(File.join(folder, 'index.md'))
        .and_return("---\nname: 'AI Proxy Advanced'\nicon: ai-proxy-advanced.png\n---\n")
    end

    it { expect(plugin.icon).to eq('ai-proxy-advanced.png') }
  end
end
