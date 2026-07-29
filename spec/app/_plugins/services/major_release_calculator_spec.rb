# frozen_string_literal: true

RSpec.describe MajorReleaseCalculator do
  context 'when major_version is set' do
    subject(:calc) { described_class.new({ 'major_version' => { 'ai-gateway' => 1 } }) }

    it { expect(calc.previous_major?).to be true }
    it { expect(calc.major_version).to eq({ 'ai-gateway' => 1 }) }
  end

  context 'when major_version is absent' do
    subject(:calc) { described_class.new({}) }

    it { expect(calc.previous_major?).to be false }
    it { expect(calc.major_version).to be_nil }
  end

  context 'when major_version is nil' do
    subject(:calc) { described_class.new({ 'major_version' => nil }) }

    it { expect(calc.previous_major?).to be false }
    it { expect(calc.major_version).to be_nil }
  end
end
