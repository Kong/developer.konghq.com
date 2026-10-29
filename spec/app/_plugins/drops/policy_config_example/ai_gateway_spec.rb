# frozen_string_literal: true

RSpec.describe Jekyll::Drops::PolicyConfigExample::AIGateway do
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

  let(:scopes) { %w[ai-model ai-consumer global] }

  let(:plugin) do
    double(
      'policy',
      product: 'ai-gateway',
      slug: 'ai-sanitizer',
      scopes: scopes,
      unreleased?: false,
      min_release: nil
    )
  end

  before { File.write(file, example_yaml) }

  subject(:drop) { described_class.new(file:, plugin:) }

  it { expect(drop.product).to eq('ai-gateway') }

  it 'builds the example URL from the policy slug and the example file' do
    expect(drop.url).to eq('/ai-gateway/policies/ai-sanitizer/examples/sanitize-pii/')
  end

  describe '#targets' do
    context 'without a scopes key in the example' do
      it 'defaults to the policy scopes' do
        expect(drop.targets).to eq(%w[ai-model ai-consumer global])
      end
    end

    context 'with a scopes subset in the example' do
      let(:example_yaml) do
        <<~YAML
          title: Sanitize PII
          description: Sanitize PII from model responses.
          weight: 100
          name: pii-sanitizer
          display_name: PII Sanitizer
          type: ai-sanitizer
          scopes:
            - global
          config:
            patterns:
              - email
          tools:
            - konnect-api
            - terraform
            - kongctl
        YAML
      end

      it 'restricts the targets to the subset' do
        expect(drop.targets).to eq(['global'])
      end
    end
  end

  describe '#data' do
    it 'holds the policy fields with enabled defaulting to true and no condition key' do
      expect(drop.data).to eq(
        'name' => 'pii-sanitizer',
        'display_name' => 'PII Sanitizer',
        'type' => 'ai-sanitizer',
        'enabled' => true,
        'config' => { 'patterns' => ['email'] }
      )
    end

    context 'with enabled false and a condition' do
      let(:example_yaml) do
        <<~YAML
          title: Sanitize PII
          description: Sanitize PII from model responses.
          weight: 100
          name: pii-sanitizer
          display_name: PII Sanitizer
          type: ai-sanitizer
          enabled: false
          condition: '{"type":"json","key":"model"}'
          config:
            patterns:
              - email
          tools:
            - konnect-api
            - terraform
            - kongctl
        YAML
      end

      it 'holds the overridden enabled and the condition' do
        expect(drop.data).to include(
          'enabled' => false,
          'condition' => '{"type":"json","key":"model"}'
        )
      end
    end
  end

  describe 'build errors' do
    context 'with an unsupported scope in the subset' do
      let(:example_yaml) do
        <<~YAML
          title: Sanitize PII
          description: Sanitize PII from model responses.
          weight: 100
          name: pii-sanitizer
          display_name: PII Sanitizer
          type: ai-sanitizer
          scopes:
            - ai-consumer-group
          config:
            patterns:
              - email
          tools:
            - konnect-api
            - terraform
            - kongctl
        YAML
      end

      it 'raises naming the file and the supported scopes' do
        expect { drop }
          .to raise_error(
            ArgumentError,
            "Invalid `scopes` in #{file}, supported scopes: ai-model, ai-consumer, global"
          )
      end
    end

    context 'with global set in the example' do
      let(:example_yaml) do
        <<~YAML
          title: Sanitize PII
          description: Sanitize PII from model responses.
          weight: 100
          name: pii-sanitizer
          display_name: PII Sanitizer
          type: ai-sanitizer
          global: true
          config:
            patterns:
              - email
          tools:
            - konnect-api
            - terraform
            - kongctl
        YAML
      end

      it 'raises naming the file and stating that the target sets global' do
        expect { drop }
          .to raise_error(
            ArgumentError,
            "Invalid `global` in #{file}: the target sets `global`, remove the `global` key"
          )
      end
    end

    context 'with a missing display_name' do
      let(:example_yaml) do
        <<~YAML
          title: Sanitize PII
          description: Sanitize PII from model responses.
          weight: 100
          name: pii-sanitizer
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

      it 'raises naming the file' do
        expect { drop }
          .to raise_error(ArgumentError, "Missing `display_name` in #{file}")
      end
    end

    context 'with an unsupported tool' do
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
            - deck
        YAML
      end

      it 'raises naming the file and the supported tools' do
        expect { drop }
          .to raise_error(
            ArgumentError,
            "Invalid `tools` in #{file}, supported tools: konnect-api, terraform, kongctl"
          )
      end
    end
  end
end
