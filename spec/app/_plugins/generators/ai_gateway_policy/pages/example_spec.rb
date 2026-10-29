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

  describe 'rendered page' do
    before do
      allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance])
      allow(CodeHighlighter).to receive(:new).and_return(instance_double(CodeHighlighter, highlight: 'HIGHLIGHTED'))
    end

    describe 'HTML output' do
      subject(:rendered) do
        render_liquid(page.content, page: page.data.merge('output_format' => 'html'))
      end

      let(:html) { Capybara::Node::Simple.new(rendered) }

      it 'renders the attach note in the entity panel after the tool snippets' do
        panel = html.find('[data-target="ai-model"]')
        expect(panel).to have_css('.entity-example-format-panel', count: 3)
        expect(panel).to have_css(
          '.entity-example-target-note',
          text: 'After creating the policy, add pii-sanitizer to the policies array of your AI Model.'
        )
        expect(panel).to have_css('.entity-example-format-panel + .entity-example-target-note')
        expect(panel).to have_link('AI Model', href: '/ai-gateway/entities/ai-model/')
      end

      it 'renders no attach note in the global panel' do
        expect(html).to have_css('[data-target="global"]')
        expect(html).not_to have_css('[data-target="global"] .entity-example-target-note')
      end
    end

    describe 'Markdown output' do
      subject(:rendered) do
        render_liquid(page.content, page: page.data.merge('output_format' => 'markdown'))
      end

      it 'renders the attach note under the target heading after the last tool snippet' do
        expect(rendered).to include('#### AI Model')
        expect(rendered).to include(
          'After creating the policy, add `pii-sanitizer` to the `policies` array of ' \
          'your [AI Model](/ai-gateway/entities/ai-model/).'
        )
        expect(rendered.index('After creating the policy')).to be > rendered.rindex('data-tool="kongctl"')
      end
    end
  end
end
