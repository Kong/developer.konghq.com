# frozen_string_literal: true

RSpec.describe Jekyll::Drops::Concerns::RequestSnippetConfig do
  let(:drop_class) do
    Class.new(Liquid::Drop) do
      include Jekyll::Drops::Concerns::RequestSnippetConfig

      def initialize(yaml) # rubocop:disable Lint/MissingSuper
        @yaml = yaml
      end

      def [](key)
        key = key.to_s
        if respond_to?(key)
          public_send(key)
        elsif @yaml.key?(key)
          @yaml[key]
        end
      end

      def method
        @yaml['method']
      end
    end
  end

  subject(:drop) { drop_class.new(yaml) }

  let(:yaml) { { 'url' => '/anything', 'method' => 'POST', 'count' => 3 } }

  it 'exposes 21 keys' do
    expect(described_class::SNIPPET_KEYS.size).to eq(21)
  end

  it 'does not expose a top level jq' do
    expect(described_class::SNIPPET_KEYS).not_to include('jq')
  end

  it 'returns every snippet key and nothing else' do
    expect(drop.snippet_config_for('https://example.com/anything').keys)
      .to eq(described_class::SNIPPET_KEYS)
  end

  it 'replaces the url with the resolved one' do
    expect(drop.snippet_config_for('https://example.com/anything')['url'])
      .to eq('https://example.com/anything')
  end

  it 'reads every other option through the drop' do
    config = drop.snippet_config_for('https://example.com/anything')

    expect(config['method']).to eq('POST')
    expect(config['count']).to eq(3)
  end

  it 'leaves an unset option nil' do
    expect(drop.snippet_config_for('https://example.com/anything')['body']).to be_nil
  end

  context 'when the drop overrides an option' do
    let(:drop_class) do
      Class.new(super()) do
        def snippet_config_overrides
          { 'count' => self['iterations'] }
        end
      end
    end

    let(:yaml) { { 'url' => '/anything', 'iterations' => 5 } }

    it 'applies the override after the key list' do
      expect(drop.snippet_config_for('https://example.com/anything')['count']).to eq(5)
    end
  end
end
