# frozen_string_literal: true

RSpec.describe Jekyll::Drops::PluginCredentialExample::Presenters::AdminAPI do
  before { stub_entity_examples_config! }

  def build_drop(file)
    Jekyll::Drops::PluginCredentialExample.new(
      plugin_name: 'Plugin',
      example_formats: %w[admin-api],
      definition: YAML.load_file(file)
    )
  end

  {
    'key-auth' => { 'key' => 'hello_world' },
    'basic-auth' => { 'username' => 'alex', 'password' => 'hello_world' },
    'hmac-auth' => { 'username' => 'alex', 'secret' => 'hello_world' },
    'jwt' => { 'key' => 'hello_world', 'algorithm' => 'HS256', 'secret' => 'hello_world_secret' }
  }.each do |slug, expected_data|
    context "for #{slug}" do
      subject(:presenter) do
        described_class.new(credential_example: build_drop("app/_data/plugins/credentials/#{slug}.yml"))
      end

      it 'requests the Consumer collection endpoint with the Consumer body' do
        expect(presenter.consumer_request.url).to eq('http://localhost:8001/consumers/')
        expect(presenter.consumer_request.data).to eq('username' => 'alex')
      end

      it "requests the #{slug} credential path under the Consumer, with the credential body" do
        expect(presenter.credential_request.url).to eq("http://localhost:8001/consumers/alex/#{slug}")
        expect(presenter.credential_request.data).to eq(expected_data)
      end
    end
  end
end
