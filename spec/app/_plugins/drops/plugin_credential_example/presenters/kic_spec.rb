# frozen_string_literal: true

RSpec.describe Jekyll::Drops::PluginCredentialExample::Presenters::KIC do
  subject(:presenter) do
    described_class.new(
      credential_example: Jekyll::Drops::PluginCredentialExample.new(
        plugin_name: 'Key Auth',
        example_formats: %w[kic],
        definition: YAML.load_file('app/_data/plugins/credentials/key-auth.yml')
      )
    )
  end

  it 'names the Secret after the Consumer username and the credential endpoint' do
    expect(presenter.secret_name).to eq('alex-key-auth')
  end

  it 'dispatches to the kic template' do
    expect(presenter.template_file).to eq('/components/plugin_credential_example/format/kic.md')
  end
end
