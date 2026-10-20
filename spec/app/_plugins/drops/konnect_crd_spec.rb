# frozen_string_literal: true

RSpec.describe Jekyll::Drops::KonnectCrd do
  subject(:drop) { described_class.new(yaml: yaml, format: 'html') }

  let(:yaml) do
    {
      'kind' => 'KonnectAPIAuthConfiguration',
      'metadata' => {
        'name' => 'konnect-api-auth',
        'namespace' => 'kong'
      },
      'spec' => {
        'type' => 'token',
        'token' => '$KONNECT_TOKEN'
      }
    }
  end

  describe 'the test section' do
    it 'defaults to step' do
      expect(drop.section).to eq('step')
    end

    it 'returns data-test-step' do
      expect(drop.test_attribute).to eq('data-test-step')
    end

    context 'when the writer sets section: prereqs' do
      let(:yaml) { super().merge('section' => 'prereqs') }

      it 'returns data-test-prereq' do
        expect(drop.test_attribute).to eq('data-test-prereq')
      end
    end

    context 'when the writer sets section: cleanup' do
      let(:yaml) { super().merge('section' => 'cleanup') }

      it 'returns data-test-cleanup' do
        expect(drop.test_attribute).to eq('data-test-cleanup')
      end
    end

    context 'when the writer sets an unrecognized section' do
      let(:yaml) { super().merge('section' => 'prereq') }

      it 'raises ArgumentError naming the rejected value' do
        expect { drop }.to raise_error(ArgumentError, /prereq/)
      end
    end
  end

  describe '#create_namespace' do
    it 'returns nil when the writer does not set it' do
      expect(drop.create_namespace).to be_nil
    end

    context 'when the writer sets it' do
      let(:yaml) { super().merge('create_namespace' => 'kong') }

      it 'returns the writer value' do
        expect(drop.create_namespace).to eq('kong')
      end
    end
  end

  describe '#crd_yaml' do
    it 'serialises the configuration as the block did' do
      expect(drop.crd_yaml).to eq(<<~YAML.chomp)
        kind: KonnectAPIAuthConfiguration
        metadata:
          name: konnect-api-auth
          namespace: kong
        spec:
          type: token
          token: "$KONNECT_TOKEN"
      YAML
    end

    it 're-quotes a quoted version value' do
      versioned = yaml.merge('spec' => { 'version' => '3.9' })
      crd_yaml = described_class.new(yaml: versioned, format: 'html').crd_yaml

      expect(crd_yaml).to include('version: "3.9"')
    end

    it 'carries neither the section nor the create_namespace key' do
      with_both = yaml.merge('section' => 'prereqs', 'create_namespace' => 'kong')
      crd_yaml = described_class.new(yaml: with_both, format: 'html').crd_yaml

      expect(YAML.safe_load(crd_yaml)).not_to include('section', 'create_namespace')
    end
  end
end
