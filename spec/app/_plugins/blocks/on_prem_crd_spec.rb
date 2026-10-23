# frozen_string_literal: true

RSpec.describe Jekyll::OnPremCrd do
  let(:page) do
    { 'output_format' => 'html', 'path' => 'test.md', 'works_on' => works_on }
  end
  let(:works_on) { %w[on-prem] }

  let(:template) do
    <<~'LIQUID'
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
      <<~'LIQUID'
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
      <<~'LIQUID'
        {% on_prem_crd %}
        indent: 3
        kind: GatewayConfiguration
        metadata:
          name: kong
          namespace: kong
        {% endon_prem_crd %}
      LIQUID
    end

    it 'prefixes every non-empty rendered line with the requested indentation' do
      expect(rendered.lines.reject { |line| line.strip.empty? }).to all(start_with('   '))
    end

    it 'keeps the indent key out of the emitted YAML' do
      expect(rendered).not_to include('indent')
    end
  end
end
