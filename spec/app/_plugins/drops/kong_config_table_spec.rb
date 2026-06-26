# frozen_string_literal: true

RSpec.describe Jekyll::Drops::KongConfigTable do
  let(:kong_conf_data) do
    {
      'params' => {
        'log_level' => { 'defaultValue' => 'notice', 'description' => 'Sets log level' },
        'proxy_listen' => { 'defaultValue' => '0.0.0.0:8000', 'description' => 'Proxy listen addr' }
      }
    }
  end

  before { stub_const('Jekyll::Drops::KongConfigTable::KONG_CONF_CACHE', { '3.8' => kong_conf_data }) }

  let(:config) do
    {
      'config' => [
        { 'name' => 'log_level' },
        { 'name' => 'proxy_listen' }
      ]
    }
  end
  let(:release_number) { '3.8' }
  let(:mode) { 'conf' }

  subject(:table) { described_class.new(config, release_number, mode) }

  describe '#params' do
    it { expect(table.params).to all(be_a(Jekyll::Drops::KongConfigTable::KongConfigField)) }
    it { expect(table.params.map(&:name)).to contain_exactly('log_level', 'proxy_listen') }
  end

  describe '#directives' do
    context 'when directives are present' do
      let(:config) do
        { 'directives' => [{ 'name' => 'some_directive', 'description' => 'Custom directive' }] }
      end

      it { expect(table.directives).to all(be_a(Jekyll::Drops::KongConfigTable::KongConfigField)) }
      it { expect(table.directives.map(&:name)).to contain_exactly('some_directive') }
    end

    context 'when no directives are present' do
      it { expect(table.directives).to be_empty }
    end
  end

  describe '#fields' do
    it 'returns all params sorted alphabetically by name' do
      expect(table.fields.map(&:name)).to eq(%w[log_level proxy_listen])
    end

    context 'with both params and directives' do
      let(:config) do
        {
          'config' => [{ 'name' => 'proxy_listen' }],
          'directives' => [{ 'name' => 'log_level', 'description' => 'Custom' }]
        }
      end

      it 'merges and sorts all fields alphabetically' do
        expect(table.fields.map(&:name)).to eq(%w[log_level proxy_listen])
      end
    end
  end

  describe 'validation' do
    context 'when a directive is missing a description' do
      let(:config) { { 'directives' => [{ 'name' => 'some_directive' }] } }

      it 'raises ArgumentError on initialization' do
        expect { table }.to raise_error(ArgumentError, /Missing description for directive/)
      end
    end

    context 'when all directives have a description' do
      let(:config) { { 'directives' => [{ 'name' => 'some_directive', 'description' => 'OK' }] } }

      it { expect { table }.not_to raise_error }
    end
  end

  context 'with env mode' do
    let(:mode) { 'env' }

    it 'prefixes param names with KONG_' do
      expect(table.params.map(&:name)).to contain_exactly('KONG_LOG_LEVEL', 'KONG_PROXY_LISTEN')
    end
  end

  describe Jekyll::Drops::KongConfigTable::KongConfigField do
    let(:kong_conf_field) { { 'defaultValue' => 'notice', 'description' => 'Field description' } }
    let(:config_entry) { { 'name' => 'log_level', 'description' => 'Config description' } }
    let(:mode) { 'conf' }

    subject(:field) { described_class.new(config_entry, kong_conf_field, mode) }

    describe '#name' do
      context 'with conf mode' do
        it { expect(field.name).to eq('log_level') }
      end

      context 'with env mode' do
        let(:mode) { 'env' }

        it { expect(field.name).to eq('KONG_LOG_LEVEL') }
      end

      context 'with empty mode (defaults to conf)' do
        let(:mode) { '' }

        it { expect(field.name).to eq('log_level') }
      end

      context 'with unknown mode' do
        let(:mode) { 'xml' }

        it 'raises RuntimeError' do
          expect { field.name }.to raise_error(RuntimeError, /Unknown kong_config_table mode/)
        end
      end
    end

    describe '#default_value' do
      it { expect(field.default_value).to eq('notice') }

      context 'when field is nil' do
        subject(:field) { described_class.new(config_entry, nil, mode) }

        it { expect(field.default_value).to be_nil }
      end

      context 'when defaultValue key is absent' do
        let(:kong_conf_field) { { 'description' => 'desc only' } }

        it { expect(field.default_value).to be_nil }
      end
    end

    describe '#array?' do
      context 'when default_value is an Array' do
        let(:kong_conf_field) { { 'defaultValue' => %w[a b] } }

        it { expect(field.array?).to be(true) }
      end

      context 'when default_value is a String' do
        it { expect(field.array?).to be(false) }
      end

      context 'when default_value is nil' do
        let(:kong_conf_field) { {} }

        it { expect(field.array?).to be_falsy }
      end
    end

    describe '#description' do
      context 'when config has a description' do
        it 'returns the config description' do
          expect(field.description).to eq('Config description')
        end
      end

      context 'when config has no description' do
        let(:config_entry) { { 'name' => 'log_level' } }

        it 'falls back to the field description' do
          expect(field.description).to eq('Field description')
        end
      end

      context 'when neither config nor field has a description' do
        let(:config_entry) { { 'name' => 'log_level' } }
        let(:kong_conf_field) { {} }

        it { expect(field.description).to be_nil }
      end
    end
  end
end
