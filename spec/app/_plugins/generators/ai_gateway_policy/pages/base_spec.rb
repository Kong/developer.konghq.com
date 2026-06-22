# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::AIGatewayPolicyPages::Pages::Base do
  let(:policy) do
    instance_double(
      Jekyll::AIGatewayPolicyPages::Policy,
      schema: { 'properties' => { 'config' => {} } },
      icon: 'my-policy.png'
    )
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
end
