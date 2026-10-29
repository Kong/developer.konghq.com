# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::AIGatewayPolicyPages::Pages::Example do
  def example_fixture(name)
    File.join(PROJECT_ROOT, 'spec/fixtures/app/_ai_gateway_policies/ai-sanitizer/examples', name)
  end

  let(:scopes) { %w[global ai-model] }

  let(:enabled_false) do
    ai_gateway_policy_config_example(file: example_fixture('enabled-false.yml'), scopes: scopes)
  end

  let(:sanitize_pii) do
    ai_gateway_policy_config_example(file: example_fixture('sanitize-pii.yml'), scopes: scopes)
  end

  let(:policy) do
    instance_double(
      Jekyll::AIGatewayPolicyPages::Policy,
      slug: 'ai-sanitizer',
      metadata: { 'title' => 'KONG', 'faqs' => [], 'scopes' => scopes },
      overview_page_class: Jekyll::AIGatewayPolicyPages::Pages::Overview,
      reference_page_class: Jekyll::AIGatewayPolicyPages::Pages::Reference,
      examples: [enabled_false, sanitize_pii],
      latest_release_in_range: '1.0',
      publish?: true,
      priority: 925,
      schema: { 'properties' => { 'config' => {} } },
      icon: nil,
      unreleased?: false,
      min_release: nil,
      overview_content: 'Some content',
      api_spec_exists?: false
    )
  end

  let(:file) { example_fixture('sanitize-pii.yml') }

  let(:page) { described_class.new(policy:, file:) }

  describe '#url' do
    it 'builds the URL from the example drop' do
      expect(page.url).to eq('/ai-gateway/policies/ai-sanitizer/examples/sanitize-pii/')
    end
  end

  describe '#layout' do
    it { expect(page.layout).to eq('policies/example') }
  end

  describe '#content' do
    it 'is the AI Gateway policies example include' do
      expect(page.content).to eq(File.read('app/_includes/ai_gateway_policies/example.md'))
    end
  end

  describe '#data' do
    subject(:data) { page.data }

    it { expect(data['example?']).to be(true) }
    it { expect(data['examples']).to eq([enabled_false, sanitize_pii]) }
    it { expect(data['content_type']).to eq('plugin_example') }
    it { expect(data['example']).to eq(sanitize_pii) }
    it { expect(data['example_title']).to eq('Sanitize PII') }
    it { expect(data['description']).to eq('Sanitize PII from model responses.') }

    it 'links the examples tab to the highest-weight example' do
      expect(data['get_started_url']).to eq('/ai-gateway/policies/ai-sanitizer/examples/enabled-false/')
    end
  end
end
