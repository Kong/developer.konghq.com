# frozen_string_literal: true

RSpec.describe 'components/plugin_credential_example/format/terraform.md' do
  let(:drop) do
    Jekyll::Drops::PluginCredentialExample.new(
      plugin_name: 'Key Auth', example_formats: %w[terraform],
      definition: YAML.load_file('app/_data/plugins/credentials/key-auth.yml')
    )
  end
  let(:presenter) { Jekyll::Drops::PluginCredentialExample::Presenters::Terraform.new(credential_example: drop) }

  let(:template) do
    '{% include components/plugin_credential_example/format/terraform.md presenter=presenter  %}'
  end

  subject(:rendered) do
    render_liquid(template, locals: { 'presenter' => presenter })
  end

  it 'renders the lead sentence, then a Consumer resource and a credential resource referencing it' do
    expect(rendered).to eq(<<~'MD')
      The Key Auth plugin needs a Consumer with a credential attached before it can authenticate requests.


      Add the following to your Terraform configuration to create the Consumer and the credential:

      ```hcl
      resource "konnect_gateway_consumer" "my_consumer" {
        username = "alex"
        control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
      }

      resource "konnect_gateway_key_auth" "my_key_auth" {
        consumer_id = konnect_gateway_consumer.my_consumer.id
        key = "hello_world"
        control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
      }
      ```
    MD
  end
end
