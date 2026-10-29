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
end
