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
    expect { items_for_published('not-a-date') }
      .to raise_error(ArgumentError, /bad\.md/)
  end

  # Date.parse accepts these, so they only fail if the parse is strict about
  # the YYYY-MM-DD shape the frontmatter schema requires.
  ['August 10, 2026', '2026/06/05', '06/05/2026', 'June 5', '20260605', '2026-6-5'].each do |value|
    it "fails on a published value of #{value.inspect} that is not YYYY-MM-DD" do
      expect { items_for_published(value) }
        .to raise_error(ArgumentError, /bad\.md/)
    end
  end

  it 'fails on a published value that matches the shape but is not a real date' do
    expect { items_for_published('2026-02-30') }
      .to raise_error(ArgumentError, /bad\.md/)
  end

  def items_for_published(value)
    bad_doc = instance_double(
      Jekyll::Document,
      data: { 'title' => 'Bad', 'advisory' => { 'published' => value } },
      url: '/support/security/bad/',
      relative_path: '_support/security/bad.md'
    )
    collection = instance_double(Jekyll::Collection, docs: [bad_doc])
    bad_site = instance_double(Jekyll::Site, collections: { 'support' => collection })
    described_class.items(bad_site)
  end
end
