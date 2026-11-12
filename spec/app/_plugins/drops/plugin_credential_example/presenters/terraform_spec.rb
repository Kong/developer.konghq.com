# frozen_string_literal: true

RSpec.describe Jekyll::Drops::PluginCredentialExample::Presenters::Terraform do
  subject(:presenter) do
    described_class.new(
      credential_example: Jekyll::Drops::PluginCredentialExample.new(
        plugin_name: 'Key Auth',
        example_formats: %w[terraform],
        definition: YAML.load_file('app/_data/plugins/credentials/key-auth.yml')
      )
    )
  end

  it 'names the credential resource per the derived Terraform resource name' do
    expect(presenter.consumer_resource_name).to eq('konnect_gateway_consumer')
    expect(presenter.credential_resource_name).to eq('konnect_gateway_key_auth')
  end

  it 'injects the Consumer reference as an unquoted value, not a literal identifier' do
    expect(presenter.credential_body).to include('consumer_id = konnect_gateway_consumer.my_consumer.id')
    expect(presenter.credential_body).not_to include('consumer_id = "')
  end

  it 'renders both the Consumer body and the credential body' do
    expect(presenter.consumer_body).to include('username = "alex"')
    expect(presenter.credential_body).to include('key = "hello_world"')
  end
end
