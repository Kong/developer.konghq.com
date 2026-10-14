# frozen_string_literal: true

RSpec.describe 'components/plugin_credential_example/format/admin-api.md' do
  before do
    JekyllSite.instance.data['entity_examples'] =
      { 'config' => YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true) }
    allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance])
  end

  after { JekyllSite.instance.data.delete('entity_examples') }

  let(:template) do
    '{% include components/plugin_credential_example/format/admin-api.md presenter=presenter %}'
  end

  subject(:rendered) do
    render_liquid(template, locals: { 'presenter' => presenter })
  end

  let(:consumer_code) { rendered[/```bash\n(.*?)\n```/m, 1] }
  let(:credential_code) { rendered[/```bash\n.*?\n```\n.*?```bash\n(.*?)\n```/m, 1] }

  shared_examples 'valid bash for both requests' do
    it 'renders syntactically valid bash for both requests' do
      validate_bash_syntax!(consumer_code)
      validate_bash_syntax!(credential_code)
    end
  end

  context 'for Basic auth' do
    let(:drop) do
      Jekyll::Drops::PluginCredentialExample.new(
        plugin_name: 'Basic Auth', example_formats: %w[admin-api],
        definition: YAML.load_file('app/_data/plugins/credentials/basic-auth.yml')
      )
    end
    let(:presenter) { Jekyll::Drops::PluginCredentialExample::Presenters::AdminAPI.new(credential_example: drop) }

    include_examples 'valid bash for both requests'

    it 'renders the lead sentence, then the intro line and curl command for each request' do
      expect(rendered).to eq(<<~MD)
        The Basic Auth plugin needs a Consumer with a credential attached before it can authenticate requests.


        Create the Consumer:

        ```bash
        curl -i -X POST http://localhost:8001/consumers/ \\
            --header "Accept: application/json" \\
            --header "Content-Type: application/json" \\
            --data '
            {
              "username": "alex"
            }
            '
        ```

        Attach the `basic-auth` credential:

        ```bash
        curl -i -X POST http://localhost:8001/consumers/alex/basic-auth \\
            --header "Accept: application/json" \\
            --header "Content-Type: application/json" \\
            --data '
            {
              "username": "alex",
              "password": "hello_world"
            }
            '
        ```
      MD
    end
  end
end
