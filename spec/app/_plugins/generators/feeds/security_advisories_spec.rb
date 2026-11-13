# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::Feeds::Sources::SecurityAdvisories do
  before { allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance]) }

  let(:site) { JekyllSite.instance }

  subject(:items) { described_class.items(site) }

  it 'sorts items newest first' do
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

  it 'returns a Time for every item' do
    expect(items.first['date']).to eq(Time.utc(2026, 6, 5))
    expect(items.last['date']).to eq(Time.utc(2024, 4, 11))
  end

  it 'returns the page url' do
    expect(items.first['url']).to eq('/support/security/fixture-lua-sandbox-bypass/')
  end

  it 'fails on a published value that is not a date' do
    bad_doc = instance_double(
      Jekyll::Document,
      data: { 'title' => 'Bad', 'advisory' => { 'published' => 'not-a-date' } },
      url: '/support/security/bad/',
      relative_path: '_support/security/bad.md'
    )
    collection = instance_double(Jekyll::Collection, docs: [bad_doc])
    bad_site = instance_double(Jekyll::Site, collections: { 'support' => collection })
    expect { described_class.items(bad_site) }
      .to raise_error(ArgumentError, /bad\.md/)
  end
end
