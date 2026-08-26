# frozen_string_literal: true

RSpec.describe 'components/entity_example/format/snippets/kongctl.md' do
  before { stub_entity_examples_config! }

  let(:drop) { Jekyll::EntityExampleBlock::Base.make_for(example: example, product: product).to_drop }
  let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Kongctl::Base.new(example_drop: drop) }

  subject(:rendered) do
    render_liquid(
      '{% include components/entity_example/format/snippets/kongctl.md presenter=presenter %}',
      locals: { 'presenter' => presenter }
    )
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
          - kongctl
      YAML
    end

    it 'renders the ai-gateway model under a lookup-referenced ai_gateway' do
      expect(rendered).to eq(<<~'MD')
        ```yaml
        ai_gateway_models:
          - ref: my-gpt-4o
            ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
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
                - "/v1"
                model:
                  body_param: model
                  values:
                  - my-gpt-4o
              logging:
                payloads: false
        ```
        {: data-file="model.yaml" }
      MD
    end
  end

  context 'ai-gateway product, with a declared variable' do
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
                  value: "${auth_header}"
        variables:
          auth_header:
            value: $OPENAI_AUTH_HEADER
        formats:
          - kongctl
      YAML
    end

    it 'renders the substituted variable as an !env tag' do
      expect(rendered).to eq(<<~'MD')
        ```yaml
        ai_gateway_model_providers:
          - ref: my-openai-account
            ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
            display_name: OpenAI Production
            name: my-openai-account
            type: openai
            config:
              auth:
                type: basic
                headers:
                - name: Authorization
                  value: !env OPENAI_AUTH_HEADER
        ```
        {: data-file="model-provider.yaml" }
      MD
    end
  end

  context 'ai-gateway product, with a secret variable' do
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
                  value: "${auth_header}"
        variables:
          auth_header:
            value: $OPENAI_AUTH_HEADER
            secret: true
        formats:
          - kongctl
      YAML
    end

    it 'renders the substituted variable as a secret-wrapped !env tag' do
      expect(rendered).to eq(<<~'MD')
        ```yaml
        ai_gateway_model_providers:
          - ref: my-openai-account
            ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
            display_name: OpenAI Production
            name: my-openai-account
            type: openai
            config:
              auth:
                type: basic
                headers:
                - name: Authorization
                  value: !secret {source: !env OPENAI_AUTH_HEADER}
        ```
        {: data-file="model-provider.yaml" }
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
          - kongctl
      YAML
    end

    it 'renders the backend cluster nested under a placeholder event gateway' do
      expect(rendered).to eq(<<~'MD')
        ```yaml
        event_gateways:
          - ref: eventGatewayName
            name: eventGatewayName
            backend_clusters:
            - ref: example-backend-cluster
              name: example-backend-cluster
              bootstrap_servers:
              - host:9092
              authentication:
                type: anonymous
              insecure_allow_anonymous_virtual_cluster_auth: true
              tls:
                insecure_skip_verify: false
        ```
        {: data-file="backend_cluster.yaml" }
      MD
    end
  end

  context 'event-gateway product, with a bare env var value' do
    let(:product) { 'event-gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: static_key
        data:
          name: my-key
          value: $MY_KEY
        formats:
          - kongctl
      YAML
    end

    it 'renders the bare $VAR value as an !env tag' do
      expect(rendered).to eq(<<~'MD')
        ```yaml
        event_gateways:
          - ref: eventGatewayName
            name: eventGatewayName
            static_keys:
            - ref: my-key
              name: my-key
              value: !env MY_KEY
        ```
        {: data-file="static_key.yaml" }
      MD
    end
  end
end
