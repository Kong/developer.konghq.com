# frozen_string_literal: true

RSpec.describe 'components/entity_example/format/snippets/konnect-api.md' do
  before { stub_entity_examples_config! }

  let(:drop) { Jekyll::EntityExampleBlock::Base.make_for(example: example, product: product).to_drop }

  subject(:rendered) do
    render_liquid(
      '{% include components/entity_example/format/snippets/konnect-api.md presenter=presenter %}',
      locals: { 'presenter' => presenter }
    )
  end

  context 'gateway product, no variables' do
    let(:product) { 'gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: route
        data:
          name: example-route
          paths:
            - /mock
        formats:
          - konnect-api
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KonnectAPI::Base.new(example_drop: drop) }

    it 'falls back to the KONNECT_TOKEN placeholder for the PAT' do
      expect(rendered).to eq(<<~'MD')
        ```bash
        curl -X POST https://{region}.api.konghq.com/v2/control-planes/{controlPlaneId}/core-entities/routes/ \
            --header "accept: application/json" \
            --header "Content-Type: application/json" \
            --header "Authorization: Bearer $KONNECT_TOKEN" \
            --data '
            {
              "name": "example-route",
              "paths": [
                "/mock"
              ]
            }
            '
        ```
      MD
    end
  end

  context 'gateway product, plugin type with a declared variable' do
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
          - konnect-api
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KonnectAPI::Plugin.new(example_drop: drop) }

    it 'substitutes the variable and quotes it in the body' do
      expect(rendered).to eq(<<~'MD')
        ```bash
        curl -X POST https://{region}.api.konghq.com/v2/control-planes/{controlPlaneId}/core-entities/plugins/ \
            --header "accept: application/json" \
            --header "Content-Type: application/json" \
            --header "Authorization: Bearer $KONNECT_TOKEN" \
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

  context 'ai-gateway product, no variables' do
    let(:product) { 'ai-gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: model
        data:
          display_name: my-gpt-4o
          name: my-gpt-4o
          type: model
          capabilities:
            - generate
          formats:
            - type: openai
          policies: []
          targets:
            - name: gpt-4o
              provider: my-openai-account
              config:
                type: openai
          config:
            route:
              paths:
                - /v1
              model:
                body_param: model
                values:
                  - my-gpt-4o
            logging:
              payloads: false
        formats:
          - konnect-api
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KonnectAPI::Base.new(example_drop: drop) }

    it 'builds the ai-gateway url with the AIGatewayId placeholder' do
      expect(rendered).to eq(<<~'MD')
        ```bash
        curl -X POST https://{region}.api.konghq.com/v1/ai-gateways/{AIGatewayId}/models \
            --header "accept: application/json" \
            --header "Content-Type: application/json" \
            --header "Authorization: Bearer $KONNECT_TOKEN" \
            --data '
            {
              "display_name": "my-gpt-4o",
              "name": "my-gpt-4o",
              "type": "model",
              "capabilities": [
                "generate"
              ],
              "formats": [
                {
                  "type": "openai"
                }
              ],
              "policies": [],
              "targets": [
                {
                  "name": "gpt-4o",
                  "provider": "my-openai-account",
                  "config": {
                    "type": "openai"
                  }
                }
              ],
              "config": {
                "route": {
                  "paths": [
                    "/v1"
                  ],
                  "model": {
                    "body_param": "model",
                    "values": [
                      "my-gpt-4o"
                    ]
                  }
                },
                "logging": {
                  "payloads": false
                }
              }
            }
            '
        ```
      MD
    end
  end

  context 'ai-gateway product, model-provider type with a declared variable' do
    let(:product) { 'ai-gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: model-provider
        data:
          display_name: OpenAI Production
          name: my-openai-account
          type: openai
          config:
            auth:
              type: basic
              headers:
                - name: Authorization
                  value: "${key}"
        variables:
          key:
            value: $OPENAI_API_KEY
            description: The API key used to connect to OpenAI.
        formats:
          - konnect-api
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KonnectAPI::Base.new(example_drop: drop) }

    it 'substitutes the ${key} placeholder and quotes it in the body' do
      expect(rendered).to eq(<<~'MD')
        ```bash
        curl -X POST https://{region}.api.konghq.com/v1/ai-gateways/{AIGatewayId}/model-providers \
            --header "accept: application/json" \
            --header "Content-Type: application/json" \
            --header "Authorization: Bearer $KONNECT_TOKEN" \
            --data '
            {
              "display_name": "OpenAI Production",
              "name": "my-openai-account",
              "type": "openai",
              "config": {
                "auth": {
                  "type": "basic",
                  "headers": [
                    {
                      "name": "Authorization",
                      "value": "'$OPENAI_API_KEY'"
                    }
                  ]
                }
              }
            }
            '
        ```
      MD
    end
  end

  context 'event-gateway product, no variables' do
    let(:product) { 'event-gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: backend_cluster
        data:
          name: example-backend-cluster
          bootstrap_servers:
            - "host:9092"
          authentication:
            type: anonymous
          insecure_allow_anonymous_virtual_cluster_auth: true
          tls:
            insecure_skip_verify: false
        formats:
          - konnect-api
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::KonnectAPI::Base.new(example_drop: drop) }

    it 'builds the event-gateway url with the eventGatewayId placeholder' do
      expect(rendered).to eq(<<~'MD')
        ```bash
        curl -X POST https://{region}.api.konghq.com/v1/event-gateways/{eventGatewayId}/backend-clusters \
            --header "accept: application/json" \
            --header "Content-Type: application/json" \
            --header "Authorization: Bearer $KONNECT_TOKEN" \
            --data '
            {
              "name": "example-backend-cluster",
              "bootstrap_servers": [
                "host:9092"
              ],
              "authentication": {
                "type": "anonymous"
              },
              "insecure_allow_anonymous_virtual_cluster_auth": true,
              "tls": {
                "insecure_skip_verify": false
              }
            }
            '
        ```
      MD
    end
  end
end
