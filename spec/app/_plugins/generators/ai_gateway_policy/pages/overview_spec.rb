# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::AIGatewayPolicyPages::Pages::Overview do
  let(:policy) do
    instance_double(
      Jekyll::AIGatewayPolicyPages::Policy,
      slug: 'my-policy',
      metadata: { 'title' => 'My Policy', 'scopes' => %w[ai-model global] },
      overview_page_class: described_class,
      reference_page_class: Jekyll::AIGatewayPolicyPages::Pages::Reference,
      examples: [],
      latest_release_in_range: '1.0',
      publish?: true,
      schema: { 'properties' => { 'config' => {} } },
      icon: nil,
      unreleased?: false,
      min_release: nil
    )
  end

  let(:file) { 'app/_ai_gateway_policies/my-policy/index.md' }
  let(:page) { described_class.new(policy:, file:) }

  describe '.url' do
    context 'when the policy is released' do
      it { expect(described_class.url(policy)).to eq('/ai-gateway/policies/my-policy/') }
    end

    context 'when the policy is unreleased' do
      before do
        allow(policy).to receive(:unreleased?).and_return(true)
        allow(policy).to receive(:min_release).and_return('2.0')
      end

      it { expect(described_class.url(policy)).to eq('/ai-gateway/policies/my-policy/2.0/') }
    end
  end

  describe '#layout' do
    it { expect(page.layout).to eq('policies/with_aside') }
  end

  describe '#content' do
    it 'returns the body of the index.md file' do
      allow(File).to receive(:read).with(file).and_return("---\ntitle: My Policy\n---\nSome content")
      expect(page.content).to eq('Some content')
    end
  end

  describe '#data' do
    subject(:data) { page.data }

    before do
      allow(File).to receive(:read).with(file).and_return("---\ntitle: My Policy\n---\n")
    end

    it { expect(data['overview?']).to be(true) }
    it { expect(data['has_overview?']).to be(false) }
    it { expect(data['overview_url']).to eq('/ai-gateway/policies/my-policy/') }
    it { expect(data['schema']).to eq({ 'properties' => { 'config' => {} } }) }
    it { expect(data['scopes']).to eq(%w[ai-model global]) }
  end
end
