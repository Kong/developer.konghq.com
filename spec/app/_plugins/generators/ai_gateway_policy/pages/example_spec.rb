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

  let(:policy_examples) { [enabled_false, sanitize_pii] }

  let(:policy) do
    instance_double(
      Jekyll::AIGatewayPolicyPages::Policy,
      slug: 'ai-sanitizer',
      metadata: { 'title' => 'KONG', 'faqs' => [], 'scopes' => scopes },
      overview_page_class: Jekyll::AIGatewayPolicyPages::Pages::Overview,
      reference_page_class: Jekyll::AIGatewayPolicyPages::Pages::Reference,
      examples: policy_examples,
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
      let(:attach_section) { html.all('.entity-example').last }

      it 'renders the attach block as its own section with an anchored heading' do
        expect(html).to have_css('.entity-example', count: 2)
        expect(html).to have_css('h3 a[href="#attach-the-policy"]', text: 'Attach the policy')
      end

      it 'renders the note directly above the attach snippet in every tool panel' do
        panel = attach_section.find('.entity-example-target-panel[data-target="ai-model"]')

        expect(panel).to have_css('.entity-example-format-panel', count: 3)
        panel.all('.entity-example-format-panel').each do |format_panel|
          expect(format_panel).to have_css(
            '.entity-example-target-note',
            text: 'After creating the policy, add pii-sanitizer to the policies array of your AI Model.'
          )
          expect(format_panel).to have_css('.entity-example-target-note + .entity-example-target-example')
        end
      end

      it 'links the note to the entity reference page' do
        expect(attach_section).to have_link('AI Model', href: '/ai-gateway/entities/ai-model/')
      end

      it 'renders no attach panel for the global target' do
        expect(attach_section).not_to have_css('[data-target="global"]')
      end

      it 'declares the attach block a follower of the scope selection' do
        expect(attach_section[:'data-follow-target']).to eq('true')
      end

      it 'labels each policy panel with the selector of the policy section' do
        policy_section = html.all('.entity-example').first
        target_panel = policy_section.find('.entity-example-target-panel[data-target="ai-model"]')
        format_panel = target_panel.find('.entity-example-format-panel[data-format="terraform"]')

        expect(target_panel[:'aria-labelledby']).to eq(policy_section.find('select.select-target')[:id])
        expect(format_panel[:'aria-labelledby']).to eq(policy_section.find('select.select-format')[:id])
      end

      it 'resolves every aria-labelledby reference on the page' do
        expect(dangling_aria_labelledby_ids(html)).to eq([])
      end

      context 'with several non-global targets' do
        let(:scopes) { %w[global ai-model ai-consumer] }

        it 'renders a panel per non-global target and no scope selector of its own' do
          expect(attach_section).not_to have_css('select.select-target')
          expect(html).to have_css('.entity-example select.select-target', count: 1)
          expect(attach_section.all('.entity-example-target-panel').map { |panel| panel[:'data-target'] })
            .to eq(%w[ai-model ai-consumer])
        end

        it 'labels each attach panel with the section heading' do
          expect(attach_section.all('.entity-example-target-panel').map { |panel| panel[:'aria-labelledby'] })
            .to eq(%w[attach-the-policy attach-the-policy])
        end
      end

      context 'with a global-only example' do
        let(:scopes) { %w[global] }

        it 'renders no attach section' do
          expect(html).to have_css('.entity-example', count: 1)
          expect(html).not_to have_css('h3 a[href="#attach-the-policy"]')
          expect(html).not_to have_css('.entity-example-target-example')
        end
      end

      context 'with a single non-global target' do
        let(:scopes) { %w[ai-model] }

        it 'renders the attach section even though no scope selector exists' do
          expect(html).not_to have_css('select.select-target')
          expect(html).to have_css('h3 a[href="#attach-the-policy"]', text: 'Attach the policy')
          expect(attach_section).to have_css('.entity-example-target-panel[data-target="ai-model"]')
          expect(attach_section[:'data-follow-target']).to eq('true')
        end
      end

      context 'when the example lists a single tool' do
        let(:file) { example_fixture('single-tool.yml') }

        let(:single_tool) do
          ai_gateway_policy_config_example(file: example_fixture('single-tool.yml'), scopes: scopes)
        end

        let(:policy_examples) { [single_tool] }

        it 'renders the attach snippet only in that tool panel' do
          panel = attach_section.find('.entity-example-target-panel[data-target="ai-model"]')

          expect(panel).to have_css('.entity-example-format-panel', count: 1)
          expect(panel).to have_css('.entity-example-format-panel[data-format="konnect-api"]')
          expect(panel).to have_css('.entity-example-target-example', count: 1)
        end

        it 'labels the panels that have no tool selector with their section heading' do
          policy_section = html.all('.entity-example').first
          target_panel = policy_section.find('.entity-example-target-panel[data-target="ai-model"]')

          expect(target_panel.find('.entity-example-format-panel')[:'aria-labelledby']).to eq('set-up-the-policy')
          expect(attach_section.find('.entity-example-format-panel')[:'aria-labelledby']).to eq('attach-the-policy')
        end
      end
    end

    describe 'Markdown output' do
      subject(:rendered) do
        render_liquid(page.content, page: page.data.merge('output_format' => 'markdown'))
      end

      let(:attach_section) { rendered[/### Attach the policy.*/m] }

      it 'renders the attach block as its own section after the policy section' do
        expect(rendered.index('### Attach the policy')).to be > rendered.index('### Set up the policy')
      end

      it 'nests the target and tool headings under the Attach the policy heading' do
        expect(attach_section.scan(/^\#{1,5} .+$/)).to eq(
          [
            '### Attach the policy',
            '#### AI Model',
            '##### Konnect API',
            '##### Terraform',
            '##### kongctl'
          ]
        )
      end

      it 'renders the note directly above each tool snippet' do
        expect(attach_section).to include(
          "##### Konnect API\n\n" \
          'After creating the policy, add `pii-sanitizer` to the `policies` array of ' \
          'your [AI Model](/ai-gateway/entities/ai-model/).'
        )
        expect(attach_section.index('After creating the policy')).to be < attach_section.index('curl -X PUT')
      end

      it 'renders the attach snippet for every tool' do
        expect(attach_section)
          .to include('curl -X PUT https://{region}.api.konghq.com/v1/ai-gateways/{AIGatewayId}/models/my-gpt-4o')
        expect(attach_section).to include('konnect_ai_gateway_model')
        expect(attach_section).to include("policies:\n    - !ref pii-sanitizer#name")
      end

      context 'with several non-global targets' do
        let(:scopes) { %w[global ai-model ai-consumer] }

        it 'renders every non-global target under its own heading' do
          expect(attach_section.scan(/^#### .+$/)).to eq(['#### AI Model', '#### AI Consumer'])
        end
      end

      context 'with a global-only example' do
        let(:scopes) { %w[global] }

        it 'renders no attach section' do
          expect(rendered).not_to include('### Attach the policy')
          expect(rendered).not_to include('curl -X PUT')
        end
      end

      context 'when the example lists a single tool' do
        let(:file) { example_fixture('single-tool.yml') }

        let(:single_tool) do
          ai_gateway_policy_config_example(file: example_fixture('single-tool.yml'), scopes: scopes)
        end

        let(:policy_examples) { [single_tool] }

        it 'renders the attach section with only that tool' do
          expect(attach_section.scan(/^\#{1,5} .+$/)).to eq(
            [
              '### Attach the policy',
              '#### AI Model',
              '##### Konnect API'
            ]
          )
        end
      end
    end
  end
end
