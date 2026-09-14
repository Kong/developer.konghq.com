# frozen_string_literal: true

RSpec.describe Jekyll::Drops::PluginCredentialExample::Presenters::Deck do
  def build_drop(file)
    Jekyll::Drops::PluginCredentialExample.new(
      plugin_name: 'Plugin',
      example_formats: %w[deck],
      definition: YAML.load_file(file)
    )
  end

  it 'nests the key-auth credential under the Consumer, using the plugin deck_key' do
    presenter = described_class.new(credential_example: build_drop('app/_data/plugins/credentials/key-auth.yml'))

    expect(presenter.config).to include('consumers:')
    expect(YAML.safe_load(presenter.config)).to eq(
      'consumers' => [
        { 'username' => 'alex', 'keyauth_credentials' => [{ 'key' => 'hello_world' }] }
      ]
    )
  end

  it 'nests the jwt credential under jwt_secrets, its own deck_key' do
    presenter = described_class.new(credential_example: build_drop('app/_data/plugins/credentials/jwt.yml'))

    expect(YAML.safe_load(presenter.config)).to eq(
      'consumers' => [
        {
          'username' => 'alex',
          'jwt_secrets' => [{ 'key' => 'hello_world', 'algorithm' => 'HS256', 'secret' => 'hello_world_secret' }]
        }
      ]
    )
  end
end
