# frozen_string_literal: true

RSpec.describe 'components/entity_example/format/snippets/deck.md' do
  before { stub_entity_examples_config! }

  let(:drop) { Jekyll::EntityExampleBlock::Base.make_for(example: example, product: product).to_drop }

  subject(:rendered) do
    render_liquid(
      '{% include components/entity_example/format/snippets/deck.md presenter=presenter %}',
      locals: { 'presenter' => presenter }
    )
  end

  context 'with no variables' do
    let(:product) { 'gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: route
        data:
          name: example-route
          paths:
            - /mock
        formats:
          - deck
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Deck::Base.new(example_drop: drop) }

    it 'renders the entity as a decK YAML document' do
      expect(rendered).to eq(<<~'MD')
        ```yaml
        _format_version: "3.0"
        routes:
          - name: example-route
            paths:
            - "/mock"
        ```
        {: data-file="kong.yaml" }
      MD
    end
  end

  context 'with a declared variable' do
    let(:product) { 'gateway' }
    let(:example) do
      YAML.load(<<~YAML)
        type: vault
        data:
          name: konnect
          prefix: mysecretvault
          description: Storing secrets in Konnect
          config:
            config_store_id: "${config-store-id}"
        variables:
          config-store-id:
            value: $CONFIG_STORE_ID
        formats:
          - deck
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Deck::Base.new(example_drop: drop) }

    it 'substitutes the variable with decK env-lookup syntax' do
      expect(rendered).to eq(<<~'MD')
        ```yaml
        _format_version: "3.0"
        vaults:
          - name: konnect
            prefix: mysecretvault
            description: Storing secrets in Konnect
            config:
              config_store_id: ${{ env "DECK_CONFIG_STORE_ID" }}
        ```
        {: data-file="kong.yaml" }
      MD
    end
  end

  context 'with a plugin type and a declared variable' do
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
          - deck
      YAML
    end
    let(:presenter) { Jekyll::Drops::EntityExample::Presenters::Deck::Plugin.new(example_drop: drop) }

    it 'renders the plugin under a global scope with the variable substituted' do
      expect(rendered).to eq(<<~'MD')
        ```yaml
        _format_version: "3.0"
        plugins:
          - name: ai-proxy
            config:
              route_type: llm/v1/chat
              auth:
                header_name: Authorization
                header_value: Bearer ${{ env "DECK_OPENAI_API_KEY" }}
              model:
                provider: openai
                name: gpt-5.1
                options:
                  max_tokens: 512
                  temperature: 1.0
        ```
        {: data-file="kong.yaml" }
      MD
    end
  end
end
