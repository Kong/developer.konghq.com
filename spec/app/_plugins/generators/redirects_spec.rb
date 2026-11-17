# frozen_string_literal: true

require_relative '../../../../app/_plugins/generators/redirects'

RSpec.describe Jekyll::RefirectsGenerator do
  let(:site) { JekyllSite.instance }
  let(:build_filter) { Jekyll::BuildFilter.new(env: {}) }

  around do |example|
    data_keys = %w[ai_gateway_policies event_gateway_policies kong_plugins]
    snapshot = data_keys.to_h { |key| [key, site.data[key]] }
    pages = site.pages.dup
    example.run
    site.pages.replace(pages)
    data_keys.each do |key|
      next unless snapshot[key].nil?

      site.data.delete(key)
    end
  end

  before do
    allow(Jekyll).to receive(:sites).and_return([site])
    site.data['kong_plugins'] ||= {}
    site.data['ai_gateway_policies'] ||= {}
    site.data['event_gateway_policies'] ||= {}

    generate_ai_gateway_policy_pages('ai-loom-guard')
    generate_ai_gateway_policy_pages('ai-loom-rate-limit')
    generate_event_gateway_policy_pages('acl')
    described_class.new.generate(site)
  end

  let(:redirects_page) { site.pages.find { |page| page.url == '/_redirects' } }
  let(:redirects_content) { redirects_page.content }

  it 'builds the _redirects page' do
    expect(redirects_page).not_to be_nil
  end

  it 'redirects an AI Gateway policy examples URL to its highest-weight example' do
    expect(redirects_content).to include(
      "/ai-gateway/policies/ai-loom-guard/examples/\t/ai-gateway/policies/ai-loom-guard/examples/block-requests/"
    )
  end

  it 'emits no row and no blank line for an AI Gateway policy without examples' do
    expect(redirects_content).not_to include('ai-loom-rate-limit')
    expect(redirects_content).to include(
      "/ai-gateway/policies/ai-loom-guard/examples/block-requests/" \
      "\n# Redirects for the fixture site."
    )
  end

  it 'redirects an Event Gateway policy examples URL to its highest-weight example' do
    expect(redirects_content).to include(
      "/event-gateway/policies/acl/examples/\t/event-gateway/policies/acl/examples/read-only-topic/"
    )
  end

  def generate_ai_gateway_policy_pages(slug)
    policy = Jekyll::AIGatewayPolicyPages::Policy.new(
      folder: File.join(site.source, '_ai_gateway_policies', slug),
      slug:
    )
    Jekyll::AIGatewayPolicyPages::Generator.new(site, build_filter:).generate_pages(policy)
  end

  def generate_event_gateway_policy_pages(slug)
    policy = Jekyll::EventGatewayPolicyPages::Policy.new(
      folder: File.join(site.source, '_event_gateway_policies', slug),
      slug:
    )
    Jekyll::EventGatewayPolicyPages::Generator.new(site, build_filter:).generate_pages(policy)
  end
end
