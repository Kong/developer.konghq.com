# frozen_string_literal: true

RSpec.describe Jekyll::Drops::PluginCredentialExample do
  before { stub_entity_examples_config! }

  let(:definition) { YAML.load_file('app/_data/plugins/credentials/key-auth.yml') }
  let(:example_formats) { %w[deck admin-api konnect-api kic terraform] }

  subject(:drop) do
    described_class.new(plugin_name: 'Key Auth', example_formats: example_formats, definition: definition)
  end

  describe '#formats' do
    it 'intersects the example tool list with the five supported tools, preserving supported order' do
      expect(drop.formats).to eq(%w[deck admin-api konnect-api kic terraform])
    end

    context 'when the example omits a tool' do
      let(:example_formats) { %w[deck kic] }

      it 'only offers the tools the example lists' do
        expect(drop.formats).to eq(%w[deck kic])
      end
    end

    context 'when the example lists a tool this section does not support' do
      let(:example_formats) { %w[deck ui kongctl] }

      it 'drops the unsupported tool' do
        expect(drop.formats).to eq(%w[deck])
      end
    end
  end

  describe '#consumer' do
    it 'exposes the consumer fields from the definition file' do
      expect(drop.consumer).to eq('username' => 'alex')
    end
  end

  describe '#credential' do
    it 'exposes the credential fields from the definition file' do
      expect(drop.credential).to eq(
        'endpoint' => 'key-auth',
        'deck_key' => 'keyauth_credentials',
        'data' => { 'key' => 'hello_world' }
      )
    end
  end

  describe 'derivations from credential.endpoint' do
    it 'derives the Admin API / Konnect API credential path' do
      expect(drop.admin_api_path).to eq('/consumers/alex/key-auth')
    end

    it 'derives the KIC credential label' do
      expect(drop.kic_credential_label).to eq('key-auth')
    end

    it 'derives the Terraform resource name, converting hyphens to underscores' do
      expect(drop.terraform_resource_name).to eq('konnect_gateway_key_auth')
    end

    context 'for jwt' do
      let(:definition) { YAML.load_file('app/_data/plugins/credentials/jwt.yml') }

      it 'derives konnect_gateway_jwt with no hyphen to convert' do
        expect(drop.terraform_resource_name).to eq('konnect_gateway_jwt')
      end
    end
  end

  describe '#formatted_examples' do
    it 'returns one formatted example per format, with the presenter dispatching its own template' do
      expect(drop.formatted_examples.map(&:format)).to eq(%w[deck admin-api konnect-api kic terraform])

      templates = drop.formatted_examples.to_h { |fe| [fe.format, fe.template_file] }
      expect(templates).to eq(
        'deck' => '/components/plugin_credential_example/format/deck.md',
        'admin-api' => '/components/plugin_credential_example/format/admin-api.md',
        'konnect-api' => '/components/plugin_credential_example/format/konnect-api.md',
        'kic' => '/components/plugin_credential_example/format/kic.md',
        'terraform' => '/components/plugin_credential_example/format/terraform.md'
      )
    end
  end

  describe 'validation' do
    %w[consumer.username credential.endpoint credential.deck_key credential.data].each do |missing_path|
      it "raises an error naming the plugin and the missing `#{missing_path}` key" do
        invalid_definition = {
          'consumer' => { 'username' => 'alex' },
          'credential' => { 'endpoint' => 'key-auth', 'deck_key' => 'keyauth_credentials', 'data' => { 'key' => 'x' } }
        }
        keys = missing_path.split('.')
        invalid_definition.dig(*keys[0..-2]).delete(keys.last)

        expect do
          described_class.new(plugin_name: 'Key Auth', example_formats: example_formats, definition: invalid_definition)
        end.to raise_error(ArgumentError, "Missing key `#{missing_path}` in credentials for Key Auth")
      end
    end
  end
end
