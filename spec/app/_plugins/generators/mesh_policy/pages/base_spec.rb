# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::MeshPolicyPages::Pages::Base do
  let(:product_data) { { 'previous_major_url_segment' => 'v<major>' } }
  let(:site) { instance_double(Jekyll::Site, data: { 'products' => { 'mesh' => product_data } }) }

  let(:policy) do
    instance_double(
      Jekyll::MeshPolicyPages::Policy,
      site:,
      product: 'mesh',
      explicit_major:,
      policy_major:
    )
  end

  shared_examples 'a current-major policy' do
    let(:explicit_major) { nil }
    let(:policy_major) { 3 }
  end

  shared_examples 'a v2 policy' do
    let(:explicit_major) { 2 }
    let(:policy_major) { 2 }
  end

  describe '.base_url' do
    subject(:base_url) { described_class.base_url(policy) }

    context 'for a current-major policy' do
      include_examples 'a current-major policy'

      it { is_expected.to eq('/mesh/policies/') }
    end

    context 'for a v2 policy' do
      include_examples 'a v2 policy'

      it { is_expected.to eq('/mesh/v2/policies/') }
    end
  end

  describe '.version_segment' do
    subject(:version_segment) { described_class.version_segment(policy) }

    context 'for a current-major policy' do
      include_examples 'a current-major policy'

      it { is_expected.to eq('v3') }
    end

    context 'for a v2 policy' do
      include_examples 'a v2 policy'

      it { is_expected.to eq('v2') }
    end
  end

  describe '#breadcrumbs' do
    subject(:breadcrumbs) { described_class.new(policy:, file: 'index.md').breadcrumbs }

    context 'for a current-major policy' do
      include_examples 'a current-major policy'

      it { is_expected.to eq(['/mesh/', '/mesh/policies/']) }
    end

    context 'for a v2 policy' do
      include_examples 'a v2 policy'

      it { is_expected.to eq(['/mesh/v2/', '/mesh/v2/policies/']) }
    end
  end
end
