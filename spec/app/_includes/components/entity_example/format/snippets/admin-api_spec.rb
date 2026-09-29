# frozen_string_literal: true

RSpec.describe 'components/entity_example/format/snippets/admin-api.md' do
  before { stub_entity_examples_config! }

  let(:drop) { Jekyll::EntityExampleBlock::Base.make_for(example: example, product: product).to_drop }

  subject(:rendered) do
    render_liquid(
      '{% include components/entity_example/format/snippets/admin-api.md presenter=presenter %}',
      locals: { 'presenter' => presenter }
    )
  end

  context 'with no custom headers and no variables' do
    let(:product) { 'gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: consumer
        data:
          custom_id: example-consumer-id
          username: example-consumer
          tags:
            - silver-tier
        formats:
          - admin-api
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::AdminAPI::Base.new(example_drop: drop) }

    it 'renders the curl command without a custom header line' do
      expect(rendered).to eq(<<~'MD'.chomp)
        ```bash
        curl -i -X POST http://localhost:8001/consumers/ \
            --header "Accept: application/json" \
            --header "Content-Type: application/json" \
            --data '
            {
              "custom_id": "example-consumer-id",
              "username": "example-consumer",
              "tags": [
                "silver-tier"
              ]
            }
            '
        ```
      MD
    end
  end

  context 'with a custom header and no variables' do
    let(:product) { 'gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: admin
        data:
          username: admin
          email: john@konghq.com
          rbac_token_enabled: true
        headers:
          admin-api:
            - "Kong-Admin-Token: admin-token"
        formats:
          - admin-api
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::AdminAPI::Base.new(example_drop: drop) }

    it 'renders the custom header line and quotes the bare env var in the body' do
      expect(rendered).to eq(<<~'MD'.chomp)
        ```bash
        curl -i -X POST http://localhost:8001/admins/register/ \
            --header "Accept: application/json" \
            --header "Content-Type: application/json" \
            --header "Kong-Admin-Token: admin-token" \
            --data '
            {
              "username": "admin",
              "email": "john@konghq.com",
              "rbac_token_enabled": true
            }
            '
        ```
      MD
    end
  end

  context 'with a plugin type and declared variables' do
    let(:product) { 'gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: plugin
        data:
          name: ai-proxy
          config:
            route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: "Bearer ${key}"
            model:
              provider: openai
              name: gpt-5.1
              options:
                max_tokens: 512
                temperature: 1.0
        variables:
          key:
            value: $OPENAI_API_KEY
            description: The API key to use to connect to OpenAI.
        formats:
          - admin-api
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::AdminAPI::Plugin.new(example_drop: drop) }

    it 'substitutes the ${key} placeholder and quotes it in the body' do
      expect(rendered).to eq(<<~'MD'.chomp)
        ```bash
        curl -i -X POST http://localhost:8001/plugins/ \
            --header "Accept: application/json" \
            --header "Content-Type: application/json" \
            --data '
            {
              "name": "ai-proxy",
              "config": {
                "route_type": "llm/v1/chat",
                "auth": {
                  "header_name": "Authorization",
                  "header_value": "Bearer '$OPENAI_API_KEY'"
                },
                "model": {
                  "provider": "openai",
                  "name": "gpt-5.1",
                  "options": {
                    "max_tokens": 512,
                    "temperature": 1.0
                  }
                }
              }
            }
            '
        ```
      MD
    end
  end
end
