# frozen_string_literal: true

RSpec.describe Jekyll::Drops::EntityExample::AIGatewayPolicy do
  before { stub_entity_examples_config! }

  def example_fixture(name)
    File.join(PROJECT_ROOT, 'spec/fixtures/app/_ai_gateway_policies/ai-sanitizer/examples', name)
  end

  let(:example_file) { example_fixture('sanitize-pii.yml') }
  let(:scopes) { %w[global ai-model ai-mcp-server] }

  let(:config_example) { ai_gateway_policy_config_example(file: example_file, scopes: scopes) }

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
        'condition' => 'model.name == "gpt-4o"',
        'config' => {
          'patterns' => %w[email phone],
          'fail_on_error' => true,
          'thresholds' => { 'redaction' => { 'score' => 0.9, 'actions' => %w[redact log] } },
          'providers' => { 'openai' => { 'model' => 'gpt-4o' } }
        }
      )
    end
  end
end
