# frozen_string_literal: true

RSpec.describe 'components/plugin_credential_example/format/kic.md' do
  let(:drop) do
    Jekyll::Drops::PluginCredentialExample.new(
      plugin_name: 'Key Auth', example_formats: %w[kic],
      definition: YAML.load_file('app/_data/plugins/credentials/key-auth.yml')
    )
  end
  let(:presenter) { Jekyll::Drops::PluginCredentialExample::Presenters::KIC.new(credential_example: drop) }

  let(:template) do
    '{% include components/plugin_credential_example/format/kic.md presenter=presenter %}'
  end

  subject(:rendered) do
    render_liquid(template, locals: { 'presenter' => presenter })
  end

  it 'renders the lead sentence, then a labelled Secret and a KongConsumer that references it' do
    expect(rendered).to eq(<<~'MD')
      The Key Auth plugin needs a Consumer with a credential attached before it can authenticate requests.


      Create a `Secret` labeled with the `key-auth` credential type:

      ```yaml
      apiVersion: v1
      kind: Secret
      metadata:
        name: alex-key-auth
        namespace: kong
        labels:
          konghq.com/credential: key-auth
      stringData:
        key: hello_world
      ```

      Create the `KongConsumer` and reference the `Secret`:

      ```yaml
      apiVersion: configuration.konghq.com/v1
      kind: KongConsumer
      metadata:
        name: alex
        namespace: kong
        annotations:
          kubernetes.io/ingress.class: kong
      username: alex
      credentials:
      - alex-key-auth
      ```
    MD
  end

  context 'when the credential data has multiple fields' do
    let(:drop) do
      Jekyll::Drops::PluginCredentialExample.new(
        plugin_name: 'JWT', example_formats: %w[kic],
        definition: YAML.load_file('app/_data/plugins/credentials/jwt.yml')
      )
    end

    it 'renders a stringData entry for every credential field' do
      expect(rendered).to include(<<~YAML)
        stringData:
          key: hello_world
          algorithm: HS256
          secret: hello_world_secret
      YAML
    end
  end
end
