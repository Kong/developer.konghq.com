# frozen_string_literal: true

RSpec.describe Jekyll::Drops::EntityExample::AIGatewayPolicyAttachment do
  def example_fixture(name)
    File.join(PROJECT_ROOT, 'spec/fixtures/app/_ai_gateway_policies/ai-sanitizer/examples', name)
  end

  before { allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance]) }

  def attach_example(file:, target: 'ai-model', scopes: %w[global ai-model])
    config_example = ai_gateway_policy_config_example(file: example_fixture(file), scopes: scopes)
    config_example.examples.detect { |example| example.target.key == target }.attach_example
  end

  describe '#data' do
    it 'resolves the basic config by default and appends the policy name to its empty policies' do
      expect(attach_example(file: 'sanitize-pii.yml').data).to include(
        'display_name' => 'my-gpt-4o',
        'name' => 'my-gpt-4o',
        'policies' => ['pii-sanitizer']
      )
    end

    it 'resolves the named config from attach and appends the policy name after its policies' do
      expect(attach_example(file: 'attach-named.yml').data).to include(
        'name' => 'hardened-gpt-4o',
        'policies' => %w[platform-rate-limit pii-sanitizer]
      )
    end

    it 'keeps the config policies in file order and removes the duplicated policy name' do
      expect(attach_example(file: 'attach-duplicate.yml').data).to include(
        'name' => 'duplicate-gpt-4o',
        'policies' => %w[pii-sanitizer platform-rate-limit]
      )
    end

    it 'renders only the policy name when the config has no policies key' do
      expect(attach_example(file: 'attach-no-policies.yml').data).to include(
        'name' => 'bare-gpt-4o',
        'policies' => ['pii-sanitizer']
      )
    end
  end

  describe '#formatted_examples' do
    it 'renders the attach snippet only in the tools the example lists' do
      expect(attach_example(file: 'single-tool.yml').formatted_examples.map(&:format))
        .to eq(%w[konnect-api])
    end
  end

  describe '#entity_type' do
    it 'derives the entity type from each non-global target' do
      scopes = %w[ai-model ai-agent ai-mcp-server ai-consumer ai-consumer-group]
      config_example = ai_gateway_policy_config_example(file: example_fixture('sanitize-pii.yml'), scopes: scopes)

      expect(config_example.examples.map { |example| example.attach_example.entity_type })
        .to eq(%w[model agent mcp_server consumer consumer_group])
    end
  end

  describe 'build errors' do
    it 'fails when the attach config file does not exist for the target' do
      expect { attach_example(file: 'attach-missing.yml') }
        .to raise_error(
          ArgumentError,
          'Missing `attach` config for target `ai-model`: ' \
          'app/_data/entity_examples/ai-gateway/ai-model/does-not-exist.yml'
        )
    end

    it "fails when an attach key names a target the example doesn't render" do
      expect { ai_gateway_policy_config_example(file: example_fixture('attach-unknown-target.yml')) }
        .to raise_error(
          ArgumentError,
          a_string_including(
            'Invalid `attach` in',
            'attach-unknown-target.yml',
            'unknown target `ai-consumer`, rendered targets: global, ai-model'
          )
        )
    end
  end
end
