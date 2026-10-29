# frozen_string_literal: true

RSpec.describe Jekyll::Drops::EntityExample::AIGatewayPolicy do
  before { stub_entity_examples_config! }

  let(:dir) { Dir.mktmpdir }

  let(:file) { File.join(dir, 'sanitize-pii.yml') }

  let(:example_yaml) do
    <<~YAML
      title: Sanitize PII
      description: Sanitize PII from model responses.
      weight: 100
      name: pii-sanitizer
      display_name: PII Sanitizer
      type: ai-sanitizer
      config:
        patterns:
          - email
      tools:
        - konnect-api
        - terraform
        - kongctl
    YAML
  end

  let(:plugin) do
    double(
      'policy',
      product: 'ai-gateway',
      slug: 'ai-sanitizer',
      scopes: %w[global ai-model ai-mcp-server],
      unreleased?: false,
      min_release: nil
    )
  end

  before { File.write(file, example_yaml) }

  let(:config_example) { Jekyll::Drops::PolicyConfigExample::AIGateway.new(file:, plugin:) }

  subject(:drop) { config_example.examples.first }

  it 'uses the policy entity type' do
    expect(drop.entity_type).to eq('policy')
  end

  it 'keys the target by the scope' do
    expect(drop.target.key).to eq('global')
  end

  it 'builds one example per target, keyed by each scope' do
    expect(config_example.examples.map { |example| example.target.key })
      .to eq(%w[global ai-model ai-mcp-server])
  end

  describe '#data' do
    it 'sets global true for the global target' do
      expect(drop.data['global']).to be(true)
    end

    it 'sets global false for every entity target' do
      expect(config_example.examples[1].data['global']).to be(false)
      expect(config_example.examples[2].data['global']).to be(false)
    end

    it 'keeps the policy fields from the example' do
      expect(drop.data).to include(
        'name' => 'pii-sanitizer',
        'display_name' => 'PII Sanitizer',
        'type' => 'ai-sanitizer',
        'enabled' => true,
        'config' => { 'patterns' => ['email'] }
      )
    end
  end
end
