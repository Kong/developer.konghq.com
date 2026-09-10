# frozen_string_literal: true

RSpec.describe Jekyll::KongConfigTable do
  let(:instance) { described_class.allocate }

  describe '#product' do
    subject { instance.product }

    before { instance.instance_variable_set(:@page, page) }

    context 'when products is nil' do
      let(:page) { {} }
      it { is_expected.to eq('gateway') }
    end

    context 'when products does not include ai-gateway' do
      let(:page) { { 'products' => ['gateway'] } }
      it { is_expected.to eq('gateway') }
    end

    context 'when products includes ai-gateway' do
      let(:page) { { 'products' => ['ai-gateway'] } }
      it { is_expected.to eq('ai-gateway') }
    end

    context 'when products includes both gateway and ai-gateway' do
      let(:page) { { 'products' => ['gateway', 'ai-gateway'] } }
      it { is_expected.to eq('ai-gateway') }
    end
  end
end
