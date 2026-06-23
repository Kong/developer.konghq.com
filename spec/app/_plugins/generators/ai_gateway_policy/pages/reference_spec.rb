# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::AIGatewayPolicyPages::Pages::Reference do
  let(:policy) do
    instance_double(
      Jekyll::AIGatewayPolicyPages::Policy,
      slug: 'my-policy',
      metadata: { 'title' => 'My Policy', 'faqs' => [], 'scopes' => %w[models global] },
      overview_page_class: Jekyll::AIGatewayPolicyPages::Pages::Overview,
      reference_page_class: described_class,
      examples: [],
      latest_release_in_range: '1.0',
      publish?: true,
      schema: { 'properties' => { 'config' => {} } },
      icon: nil,
      unreleased?: false,
      min_release: nil
    )
  end

  let(:page) { described_class.new(policy:, file: '/app/_ai_gateway_policies/my-policy/reference.md') }

  describe '.url' do
    context 'when the policy is released' do
      it { expect(described_class.url(policy)).to eq('/ai-gateway/policies/my-policy/reference/') }
    end

    context 'when the policy is unreleased' do
      before do
        allow(policy).to receive(:unreleased?).and_return(true)
        allow(policy).to receive(:min_release).and_return('2.0')
      end

      it { expect(described_class.url(policy)).to eq('/ai-gateway/policies/my-policy/reference/2.0/') }
    end
  end

  describe '#layout' do
    it { expect(page.layout).to eq('ai_gateway_policies/reference') }
  end

  describe '#markdown_content' do
    it { expect(page.markdown_content).to eq(described_class::MARKDOWN_CONTENT) }
  end

  describe '#data' do
    subject(:data) { page.data }

    it { expect(data['has_overview?']).to be(false) }
    it { expect(data['reference_type']).to eq('base') }
    it { expect(data['content_type']).to eq('reference') }
    it { expect(data['reference?']).to be(true) }
    it { expect(data['toc']).to be(false) }
    it { expect(data['versioned']).to be(false) }
    it { expect(data['schema']).to eq({ 'properties' => { 'config' => {} } }) }
    it { expect(data['overview_url']).to eq('/ai-gateway/policies/my-policy/') }
    it { expect(data).not_to have_key('faqs') }
    it { expect(data['scopes']).to eq(%w[models global]) }
  end
end
