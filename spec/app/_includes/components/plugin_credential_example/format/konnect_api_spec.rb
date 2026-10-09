# frozen_string_literal: true

RSpec.describe 'components/plugin_credential_example/format/konnect-api.md' do
  before do
    JekyllSite.instance.data['entity_examples'] =
      { 'config' => YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true) }
    allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance])
  end

  after { JekyllSite.instance.data.delete('entity_examples') }

  let(:template) do
    '{% include components/plugin_credential_example/format/konnect-api.md presenter=presenter %}'
  end

  let(:drop) do
    Jekyll::Drops::PluginCredentialExample.new(
      plugin_name: 'Key Auth', example_formats: %w[konnect-api],
      definition: YAML.load_file('app/_data/plugins/credentials/key-auth.yml')
    )
  end
  let(:presenter) { Jekyll::Drops::PluginCredentialExample::Presenters::KonnectAPI.new(credential_example: drop) }

  subject(:rendered) do
    render_liquid(template, locals: { 'presenter' => presenter })
  end

  let(:consumer_code) { rendered[/```bash\n(.*?)\n```/m, 1] }
  let(:credential_code) { rendered[/```bash\n.*?\n```\n.*?```bash\n(.*?)\n```/m, 1] }

  it 'renders syntactically valid bash for both requests' do
    validate_bash_syntax!(consumer_code)
    validate_bash_syntax!(credential_code)
  end

  it 'renders both requests against the Konnect control plane core entities base URL, with the placeholders to replace' do
    expect(rendered).to eq(<<~'MD')
      The Key Auth plugin needs a Consumer with a credential attached before it can authenticate requests.


      Create the Consumer:

      ```bash
      curl -X POST https://{region}.api.konghq.com/v2/control-planes/{controlPlaneId}/core-entities/consumers/ \
          --header "accept: application/json" \
          --header "Content-Type: application/json" \
          --header "Authorization: Bearer $KONNECT_TOKEN" \
          --data '
          {
            "username": "alex"
          }
          '
      ```


      Attach the `key-auth` credential:

      ```bash
      curl -X POST https://{region}.api.konghq.com/v2/control-planes/{controlPlaneId}/core-entities/consumers/alex/key-auth \
          --header "accept: application/json" \
          --header "Content-Type: application/json" \
          --header "Authorization: Bearer $KONNECT_TOKEN" \
          --data '
          {
            "key": "hello_world"
          }
          '
      ```




      Make sure to replace the following placeholders with your own values:

      * `region`: Geographic region where your Kong Konnect is hosted and operates.

      * `controlPlaneId`: The `id` of the control plane.



      See the [Konnect Control Planes Config API reference](/api/konnect/control-planes-config/) to learn about region-specific URLs and personal access tokens.
    MD
  end
end
