# frozen_string_literal: true

RSpec.describe Jekyll::Drops::PluginCredentialExample::Presenters::KonnectAPI do
  before { stub_entity_examples_config! }

  subject(:presenter) do
    described_class.new(
      credential_example: Jekyll::Drops::PluginCredentialExample.new(
        plugin_name: 'Key Auth',
        example_formats: %w[konnect-api],
        definition: YAML.load_file('app/_data/plugins/credentials/key-auth.yml')
      )
    )
  end

  it 'targets the Konnect control plane core entities base URL, with the region and control plane placeholders' do
    expect(presenter.consumer_request.url)
      .to eq('https://{region}.api.konghq.com/v2/control-planes/{controlPlaneId}/core-entities/consumers/')
    expect(presenter.credential_request.url)
      .to eq('https://{region}.api.konghq.com/v2/control-planes/{controlPlaneId}/core-entities/consumers/alex/key-auth')
  end

  it 'sends the Consumer body, then the credential body' do
    expect(presenter.consumer_request.data).to eq('username' => 'alex')
    expect(presenter.credential_request.data).to eq('key' => 'hello_world')
  end

  it 'lists the region and control plane placeholders the reader must replace' do
    expect(presenter.missing_variables.map { |v| v['placeholder'] }).to eq(%w[region controlPlaneId])
  end
end
