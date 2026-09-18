# frozen_string_literal: true

RSpec.describe Jekyll::Drops::Concerns::TestSection do
  let(:drop_class) do
    Class.new(Liquid::Drop) do
      include Jekyll::Drops::Concerns::TestSection

      def initialize(yaml) # rubocop:disable Lint/MissingSuper
        @yaml = yaml
      end
    end
  end

  subject(:drop) { drop_class.new(yaml) }

  context 'when the yaml sets no section' do
    let(:yaml) { {} }

    it 'defaults section to step' do
      expect(drop.section).to eq('step')
    end

    it 'returns data-test-step' do
      expect(drop.test_attribute).to eq('data-test-step')
    end

    it 'does not raise' do
      expect { drop.validate_section! }.not_to raise_error
    end
  end

  context 'when the yaml sets section to prereqs' do
    let(:yaml) { { 'section' => 'prereqs' } }

    it 'returns prereqs' do
      expect(drop.section).to eq('prereqs')
    end

    it 'returns data-test-prereq' do
      expect(drop.test_attribute).to eq('data-test-prereq')
    end
  end

  context 'when the yaml sets section to cleanup' do
    let(:yaml) { { 'section' => 'cleanup' } }

    it 'returns cleanup' do
      expect(drop.section).to eq('cleanup')
    end

    it 'returns data-test-cleanup' do
      expect(drop.test_attribute).to eq('data-test-cleanup')
    end
  end

  context 'when the yaml sets an unrecognized section' do
    let(:yaml) { { 'section' => 'prereq' } }

    it 'raises ArgumentError naming the rejected value' do
      expect { drop.validate_section! }.to raise_error(ArgumentError, /prereq/)
    end
  end
end
