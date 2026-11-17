# frozen_string_literal: true

require_relative '../../../spec_helper'

RSpec.describe Jekyll::SecurityAdvisorySummary do
  let(:config) do
    {
      'ee_product_name' => 'Kong Gateway Enterprise',
      'ai_gateway_name' => 'Kong AI Gateway',
      'mesh_product_name' => 'Kong Mesh',
      'kic_product_name' => 'Kong Ingress Controller'
    }
  end

  def summary(advisory, products = %w[gateway])
    described_class.new({ 'advisory' => advisory, 'products' => products }, config)
  end

  let(:flat) do
    {
      'published' => '2026-10-13',
      'cves' => [
        { 'id' => 'CVE-2026-0001', 'severity' => 'high' },
        { 'id' => 'CVE-2026-0002', 'severity' => 'critical' }
      ],
      'fixed_versions' => ['3.13.0.2', '3.12.0.4']
    }
  end

  it 'uses the highest severity and a flat fixed list' do
    result = summary(flat, %w[gateway ai-gateway]).to_h
    expect(result).to include(
      'products' => 'Kong Gateway Enterprise, Kong AI Gateway',
      'severity' => 'Critical',
      'fixed' => '3.13.0.2, 3.12.0.4',
      'published' => '2026-10-13'
    )
  end

  it 'shows N/A and All when every CVE is not affected' do
    advisory = {
      'published' => '2026-08-10',
      'cves' => [{ 'id' => 'CVE-1', 'severity' => 'high', 'status' => 'not_affected' }],
      'fixed_versions' => ['3.4.1.2']
    }
    result = summary(advisory).to_h
    expect(result).to include('severity' => 'N/A', 'fixed' => 'All')
  end

  it 'ignores not affected CVEs when picking the severity' do
    advisory = { 'cves' => [{ 'id' => 'CVE-1', 'severity' => 'critical', 'status' => 'not_affected' },
                            { 'id' => 'CVE-2', 'severity' => 'low' }] }
    expect(summary(advisory).severity).to eq('Low')
  end

  it 'leaves severity empty when nothing states one' do
    expect(summary('cves' => [{ 'id' => 'CVE-1' }]).severity).to eq('')
  end

  it 'groups fixed versions by product when several products list them' do
    advisory = flat.merge('fixed_versions' => nil, 'products' => [
                            { 'product' => 'gateway', 'fixed_versions' => ['3.4.1.2'] },
                            { 'product' => 'mesh', 'fixed_versions' => ['2.13.8'] }
                          ])
    result = summary(advisory, %w[gateway mesh])
    expect(result.products).to eq('Kong Gateway Enterprise, Kong Mesh')
    expect(result.fixed).to eq('Kong Gateway Enterprise: 3.4.1.2; Kong Mesh: 2.13.8')
  end

  it 'leaves a not affected product out of the products and the fixed versions' do
    advisory = flat.merge('fixed_versions' => nil, 'products' => [
                            { 'product' => 'gateway', 'fixed_versions' => ['3.4.1.2'] },
                            { 'product' => 'mesh', 'status' => 'not_affected' }
                          ])
    result = summary(advisory, %w[gateway mesh])
    expect(result.products).to eq('Kong Gateway Enterprise')
    expect(result.fixed).to eq('3.4.1.2')
  end

  it 'bullets products and versions for the table cells' do
    result = summary(flat, %w[gateway ai-gateway])
    expect(result.products_markdown).to eq("- Kong Gateway Enterprise\n- Kong AI Gateway")
    expect(result.fixed_markdown).to eq("- 3.13.0.2\n- 3.12.0.4")
  end

  it 'nests versions under each product when products have their own versions' do
    advisory = flat.merge('fixed_versions' => nil, 'products' => [
                            { 'product' => 'gateway', 'fixed_versions' => %w[3.4.1.2 3.5.0.1] },
                            { 'product' => 'mesh', 'fixed_versions' => ['2.13.8'] }
                          ])
    expect(summary(advisory, %w[gateway mesh]).fixed_markdown)
      .to eq("- Kong Gateway Enterprise\n  - 3.4.1.2\n  - 3.5.0.1\n- Kong Mesh\n  - 2.13.8")
  end

  it 'leaves a single product or version as plain text' do
    advisory = flat.merge('fixed_versions' => ['3.13.0.2'])
    result = summary(advisory)
    expect(result.products_markdown).to eq('Kong Gateway Enterprise')
    expect(result.fixed_markdown).to eq('3.13.0.2')
  end

  it 'builds a feed description' do
    expect(summary(flat).description)
      .to eq('Severity: Critical. Products: Kong Gateway Enterprise. Fixed versions: 3.13.0.2, 3.12.0.4.')
  end
end

# Guards the real advisories so the index and the feed never show a row with a
# missing product or a product that the page does not list.
RSpec.describe 'security advisories frontmatter' do
  require 'yaml'
  require 'date'

  config = YAML.load_file(File.join(PROJECT_ROOT, 'jekyll.yml'))

  Dir[File.join(PROJECT_ROOT, 'app/_support/security/*.md')].sort.each do |file|
    name = File.basename(file)

    it "#{name} has a complete summary and consistent products" do
      fm = YAML.safe_load(File.read(file)[/\A---\n(.*?)\n---/m, 1], permitted_classes: [Date])
      result = Jekyll::SecurityAdvisorySummary.new(fm, config).to_h

      expect(result['products']).not_to be_empty
      expect(result['fixed']).not_to be_empty unless result['severity'].empty?
      entry_slugs = Array(fm['advisory']['products']).map { |entry| entry['product'] }
      expect(fm['products']).to include(*entry_slugs) unless entry_slugs.empty?
    end
  end
end
