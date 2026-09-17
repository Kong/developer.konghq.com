# frozen_string_literal: true

RSpec.describe 'components/plugin_credential_example/format/deck.md' do
  let(:template) do
    '{% include components/plugin_credential_example/format/deck.md presenter=presenter %}'
  end

  def build_drop(plugin_name, file)
    Jekyll::Drops::PluginCredentialExample.new(
      plugin_name: plugin_name, example_formats: %w[deck], definition: YAML.load_file(file)
    )
  end

  subject(:rendered) do
    render_liquid(template, locals: { 'presenter' => presenter })
  end

  context 'for key-auth' do
    let(:drop) { build_drop('Key Auth', 'app/_data/plugins/credentials/key-auth.yml') }
    let(:presenter) { Jekyll::Drops::PluginCredentialExample::Presenters::Deck.new(credential_example: drop) }

    it 'renders the fixed lead sentence, the intro line, and the nested decK document' do
      expect(rendered).to eq(<<~MD)
        The Key Auth plugin needs a Consumer with a credential attached before it can authenticate requests.


        The following creates the Consumer and attaches the credential in one document:

        ```yaml
        _format_version: "3.0"
        consumers:
          - username: alex
            keyauth_credentials:
            - key: hello_world
        ```
        {: data-file="kong.yaml" data-tool="deck" }
      MD
    end
  end

  context 'for jwt' do
    let(:drop) { build_drop('JWT', 'app/_data/plugins/credentials/jwt.yml') }
    let(:presenter) { Jekyll::Drops::PluginCredentialExample::Presenters::Deck.new(credential_example: drop) }

    it 'renders the jwt_secrets collection with the plugin own fields' do
      expect(rendered).to eq(<<~MD)
        The JWT plugin needs a Consumer with a credential attached before it can authenticate requests.


        The following creates the Consumer and attaches the credential in one document:

        ```yaml
        _format_version: "3.0"
        consumers:
          - username: alex
            jwt_secrets:
            - key: hello_world
              algorithm: HS256
              secret: hello_world_secret
        ```
        {: data-file="kong.yaml" data-tool="deck" }
      MD
    end
  end
end
