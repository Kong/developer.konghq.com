# frozen_string_literal: true

RSpec.describe Jekyll::EventGatewayPolicyPages::Pages::Example do
  before do
    allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance])
    allow(CodeHighlighter).to receive(:new).and_return(instance_double(CodeHighlighter, highlight: 'HIGHLIGHTED'))
  end

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

  it 'renders no attach section anywhere' do
    rendered = render_liquid(page.content, page: page.data.merge('output_format' => 'html'))

    expect(rendered).not_to include('entity-example-target-note')
    expect(rendered).not_to include('entity-example-target-example')
    expect(rendered).not_to include('attach-the-policy')

    html = Capybara::Node::Simple.new(rendered)
    expect(html).to have_css('.entity-example', count: 1)
  end

  it 'renders no attach section in the markdown output' do
    rendered = render_liquid(page.content, page: page.data.merge('output_format' => 'markdown'))

    expect(rendered).not_to include('### Attach the policy')
    expect(rendered).not_to include('!ref ')
  end

  it 'keeps the markdown sections tight' do
    rendered = render_liquid(page.content, page: page.data.merge('output_format' => 'markdown'))

    expect(rendered).to include("personal access tokens.\n\n##### Terraform")
    expect(rendered).to include("```\n\n##### kongctl")
  end
end
