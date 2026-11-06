# frozen_string_literal: true

RSpec.describe Jekyll::OnPremCrd do
  let(:page) do
    { 'output_format' => 'html', 'path' => 'test.md', 'works_on' => works_on }
  end
  let(:works_on) { %w[on-prem] }

  let(:template) do
    <<~LIQUID
      {% on_prem_crd %}
      kind: GatewayConfiguration
      metadata:
        name: kong
        namespace: kong
      {% endon_prem_crd %}
    LIQUID
  end

  subject(:rendered) { render_liquid(template, page: page) }

  let(:html) { Capybara::Node::Simple.new(rendered) }

  it 'renders a data-test-step wrapper with the on-prem topology' do
    expect(html).to have_css('div[data-deployment-topology="on-prem"][data-test-step="block"]')
  end

  context 'without works_on: on-prem' do
    let(:works_on) { %w[konnect] }

    it 'raises an error' do
      expect { rendered }.to raise_error(ArgumentError, /does not contain works_on: on-prem/)
    end
  end

  describe 'with create_namespace' do
    let(:template) do
      <<~LIQUID
        {% on_prem_crd %}
        create_namespace: kong
        kind: GatewayConfiguration
        metadata:
          name: kong
          namespace: kong
        {% endon_prem_crd %}
      LIQUID
    end

    it 'keeps the namespace-creation command' do
      expect(rendered).to include('kubectl create namespace kong')
    end

    it 'keeps the create_namespace key out of the emitted YAML' do
      expect(rendered).not_to include('create_namespace')
    end
  end

  describe 'with indent: 3' do
    let(:template) do
      <<~LIQUID
        {% on_prem_crd %}
        indent: 3
        kind: GatewayConfiguration
        metadata:
          name: kong
          namespace: kong
        {% endon_prem_crd %}
      LIQUID
    end

    let(:markdown_page) do
      { 'output_format' => 'markdown', 'path' => 'test.md', 'works_on' => works_on }
    end

    it 'renders the whole block with every line indented' do
      expect(rendered).to eq(<<-OUTPUT)
   <div data-deployment-topology="on-prem" markdown="1" data-test-step="block">
   ```bash
   echo '
   kind: GatewayConfiguration
   apiVersion: gateway-operator.konghq.com/v2beta1
   metadata:
     name: kong
     namespace: kong
   spec: {}
   ' | kubectl apply -f -
   ```
   </div>

      OUTPUT
    end

    it 'keeps the indent key out of the emitted YAML' do
      expect(rendered).not_to include('indent')
    end

    it 'indents the emitted YAML the same way in the html and markdown formats' do
      expected_yaml = <<-YAML
   kind: GatewayConfiguration
   apiVersion: gateway-operator.konghq.com/v2beta1
   metadata:
     name: kong
     namespace: kong
   spec: {}
      YAML

      expect(emitted_yaml(rendered)).to eq(expected_yaml)
      expect(emitted_yaml(render_liquid(template, page: markdown_page))).to eq(expected_yaml)
    end

    it 'emits a manifest that parses cleanly with no unexpected top-level keys' do
      parsed = YAML.safe_load(emitted_yaml(rendered))

      expect(parsed.keys).to contain_exactly('kind', 'apiVersion', 'metadata', 'spec')
    end

    def emitted_yaml(output)
      lines = output.lines
      start = lines.index { |line| line.strip == "echo '" }
      finish = lines.index { |line| line.strip.start_with?("' | kubectl apply") }

      lines[(start + 1)...finish].join
    end
  end

  describe 'with section: prereqs' do
    let(:template) do
      <<~LIQUID
        {% on_prem_crd %}
        section: prereqs
        kind: GatewayConfiguration
        metadata:
          name: kong
          namespace: kong
        {% endon_prem_crd %}
      LIQUID
    end

    it 'keeps the section key out of the emitted YAML' do
      expect(rendered).not_to include('section')
    end
  end
end
