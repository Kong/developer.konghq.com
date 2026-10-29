# frozen_string_literal: true

RSpec.describe Jekyll::EventGatewayPolicyPages::Pages::Example do
  before do
    JekyllSite.instance.data['entity_examples'] =
      { 'config' => YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true) }
    stub_entity_examples_config!
    allow(Jekyll.sites.first).to receive(:site_payload).and_return(JekyllSite.instance.site_payload)
    allow(CodeHighlighter).to receive(:new).and_return(instance_double(CodeHighlighter, highlight: 'HIGHLIGHTED'))
  end

  after { JekyllSite.instance.data.delete('entity_examples') }

  let(:file) do
    File.join(PROJECT_ROOT, 'spec/fixtures/app/_event_gateway_policies/acl/examples/read-only-topic.yml')
  end

  let(:eg_plugin) do
    double(
      'event-gateway policy',
      product: 'event-gateway',
      slug: 'acl',
      policy_target: 'virtual_cluster',
      phases: ['consume'],
      unreleased?: false,
      min_release: nil
    )
  end

  let(:eg_example) { Jekyll::Drops::PolicyConfigExample::EventGateway.new(file:, plugin: eg_plugin) }

  let(:policy) do
    instance_double(
      Jekyll::EventGatewayPolicyPages::Policy,
      slug: 'acl',
      metadata: { 'title' => 'ACL', 'faqs' => [] },
      overview_page_class: Jekyll::EventGatewayPolicyPages::Pages::Overview,
      reference_page_class: Jekyll::EventGatewayPolicyPages::Pages::Reference,
      examples: [eg_example],
      latest_release_in_range: '1.0',
      publish?: true,
      icon: nil,
      unreleased?: false,
      min_release: nil
    )
  end

  let(:page) { described_class.new(policy:, file:) }

  it 'renders the tool panels' do
    rendered = render_liquid(page.content, page: page.data.merge('output_format' => 'html'))

    html = Capybara::Node::Simple.new(rendered)
    expect(html).to have_css('[data-target="consume"]')
    expect(html).to have_css('[data-target="consume"] .entity-example-format-panel')
  end

  it 'renders no attach note anywhere' do
    rendered = render_liquid(page.content, page: page.data.merge('output_format' => 'html'))

    expect(rendered).not_to include('entity-example-target-note')
    expect(rendered).not_to include('After creating the policy')
  end
end
