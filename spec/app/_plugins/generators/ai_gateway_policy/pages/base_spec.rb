# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::AIGatewayPolicyPages::Pages::Base do
  let(:policy) do
    instance_double(
      Jekyll::AIGatewayPolicyPages::Policy,
      slug: 'my-policy',
      metadata: {},
      overview_page_class: page_url_class,
      reference_page_class: page_url_class,
      examples: [],
      latest_release_in_range: nil,
      publish?: true,
      priority: 925,
      overview_content: 'Some content',
      schema: { 'properties' => { 'config' => {} } },
      icon: 'my-policy.png',
      unreleased?: false,
      min_release: nil,
      api_spec_exists?: false
    )
  end

  let(:page_url_class) do
    Class.new do
      def self.url(_policy)
        '/ai-gateway/policies/my-policy/'
      end
    end
  end

  let(:page) { described_class.new(policy:, file: '/app/_ai_gateway_policies/my-policy/index.md') }

  describe '.base_url' do
    it { expect(described_class.base_url).to eq('/ai-gateway/policies/') }
  end

  describe '#breadcrumbs' do
    it { expect(page.breadcrumbs).to eq(['/ai-gateway/', '/ai-gateway/policies/']) }
  end

  describe '#icon' do
    context 'when policy has an icon' do
      it { expect(page.icon).to eq('/assets/icons/plugins/my-policy.png') }
    end

    context 'when policy has no icon' do
      before { allow(policy).to receive(:icon).and_return(nil) }

      it { expect(page.icon).to be_nil }
    end
  end

  describe '#data' do
    subject(:data) { page.data }

    let(:page_class) do
      Class.new(described_class) do
        def layout
          'policies/with_aside'
        end
      end
    end

    let(:page) { page_class.new(policy:, file: '/app/_ai_gateway_policies/my-policy/index.md') }

    it 'includes the resolved policy priority' do
      expect(data['priority']).to eq(925)
    end

    it 'points the priority doc URL at the AI Policy priority section' do
      expect(data['priority_doc_url']).to eq('/ai-gateway/entities/ai-policy/#ai-policy-priority')
    end

    context 'when the policy has no priority' do
      before { allow(policy).to receive(:priority).and_return(nil) }

      it 'leaves priority nil so the infobox hides the section' do
        expect(data['priority']).to be_nil
      end
    end
  end

  describe '#api_reference_data (via #data)' do
    subject(:data) { page.send(:api_reference_data) }

    context 'when the policy has no api spec' do
      it { expect(data).to eq({}) }
    end

    context 'when the policy has an api spec' do
      before { allow(policy).to receive(:api_spec_exists?).and_return(true) }

      it { expect(data['api_spec_exists?']).to be(true) }
      it { expect(data['api_reference_url']).to eq('/ai-gateway/policies/my-policy/api/') }
    end
  end
end
