# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::AIGatewayPolicyPages::Pages::ApiReference do
  let(:policy) do
    instance_double(
      Jekyll::AIGatewayPolicyPages::Policy,
      slug: 'my-policy',
      metadata: { 'title' => 'My Policy', 'scopes' => [] },
      overview_page_class: Jekyll::AIGatewayPolicyPages::Pages::Overview,
      reference_page_class: Jekyll::AIGatewayPolicyPages::Pages::Reference,
      examples: [],
      latest_release_in_range: '1.0',
      publish?: true,
      schema: { 'properties' => { 'config' => {} } },
      icon: nil,
      unreleased?: false,
      min_release: nil,
      overview_content: '',
      api_spec_exists?: true
    )
  end

  let(:spec_file) { 'api-specs/ai-gateway/policies/my-policy/openapi.yaml' }
  let(:page) { described_class.new(policy:, file: spec_file) }

  describe '.url' do
    context 'when the policy is released' do
      it { expect(described_class.url(policy)).to eq('/ai-gateway/policies/my-policy/api/') }
    end

    context 'when the policy is unreleased' do
      before do
        allow(policy).to receive(:unreleased?).and_return(true)
        allow(policy).to receive(:min_release).and_return('2.0')
      end

      it { expect(described_class.url(policy)).to eq('/ai-gateway/policies/my-policy/api/2.0/') }
    end
  end

  describe '#layout' do
    it { expect(page.layout).to eq('policies/api_reference') }
  end

  describe '#content' do
    it { expect(page.content).to eq('') }
  end

  describe '#markdown_content' do
    it 'reads the shared plugin api_reference include' do
      expect(page.markdown_content).to eq(File.read('app/_includes/plugins/api_reference.md'))
    end
  end

  describe '#data' do
    let(:raw_spec) { { 'openapi' => '3.0.0', 'info' => { 'title' => 'My Policy API' } } }

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(spec_file).and_return(raw_spec.to_yaml)
    end

    subject(:data) { page.data }

    it { expect(data['api_reference?']).to be(true) }
    it { expect(data['toc']).to be(false) }
    it { expect(data['api_spec']).to eq(raw_spec) }
    it { expect(data['layout']).to eq('policies/api_reference') }
    it { expect(data['api_spec_exists?']).to be(true) }
    it { expect(data['api_reference_url']).to eq('/ai-gateway/policies/my-policy/api/') }
  end
end
