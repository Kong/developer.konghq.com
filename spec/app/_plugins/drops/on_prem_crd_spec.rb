# frozen_string_literal: true

RSpec.describe Jekyll::Drops::OnPremCrd do
  subject(:drop) { described_class.new(yaml: yaml, format: 'html') }

  let(:yaml) do
    {
      'kind' => 'GatewayConfiguration',
      'metadata' => {
        'name' => 'kong',
        'namespace' => 'kong'
      },
      'spec' => {}
    }
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
    it 'serialises the configuration the way the block did' do
      expect(drop.crd_yaml).to eq(<<~YAML.chomp)
        kind: GatewayConfiguration
        metadata:
          name: kong
          namespace: kong
        spec: {}
      YAML
    end

    it 're-quotes a quoted version value' do
      versioned = yaml.merge('spec' => { 'version' => '3.9' })
      crd_yaml = described_class.new(yaml: versioned, format: 'html').crd_yaml

      expect(crd_yaml).to include('version: "3.9"')
    end

    it 'carries none of the section, create_namespace or indent keys' do
      with_control_keys = yaml.merge(
        'section' => 'prereqs',
        'create_namespace' => 'kong',
        'indent' => 3
      )
      crd_yaml = described_class.new(yaml: with_control_keys, format: 'html').crd_yaml

      expect(YAML.safe_load(crd_yaml)).not_to include('section', 'create_namespace', 'indent')
    end
  end

  describe '#template_file' do
    it 'always returns the on-prem html include' do
      expect(described_class.new(yaml: yaml, format: 'markdown').template_file)
        .to eq('app/_includes/on_prem_crd.html')
    end
  end
end
