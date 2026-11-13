# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::Feeds::Sources::SecurityAdvisories do
  before { allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance]) }

  let(:site) { JekyllSite.instance }

  # Every example but the malformed-date one needs a collection without the
  # invalid fixtures, so the source's strict parsing does not derail them.
  def valid_items
    advisory_docs = site.collections['support'].docs.reject do |doc|
      published = doc.data.dig('advisory', 'published')
      published == 'not-a-date' || published.nil?
    end
    collection = instance_double(Jekyll::Collection, docs: advisory_docs)
    valid_site = instance_double(Jekyll::Site, collections: { 'support' => collection })
    described_class.items(valid_site)
  end

  subject(:items) { valid_items }

  it 'sorts dated items newest first and undated items last' do
    expect(items.map { |i| i['title'] }).to eq(
      [
        'Security Advisory: {{site.base_gateway}} Lua sandbox bypass',
        'Security Advisory: KONGSA-2026-0002 Admin API token leak'
      ]
    )
  end

  it 'leaves out support documents without an advisory' do
    expect(items.map { |i| i['title'] }).not_to include('How to upgrade {{site.base_gateway}}')
  end

  it 'returns a Time for dated items and nil for undated ones' do
    expect(items.first['date']).to eq(Time.utc(2026, 6, 5))
    expect(items.last['date']).to eq(Time.utc(2024, 4, 11))
  end

  it 'returns the page url' do
    expect(items.first['url']).to eq('/support/security/fixture-lua-sandbox-bypass/')
  end

  it 'fails on a published value that is not a date' do
    expect { described_class.items(site) }
      .to raise_error(ArgumentError, /fixture-bad-date-advisory/)
  end
end
