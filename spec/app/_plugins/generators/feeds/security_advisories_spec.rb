# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::Feeds::Sources::SecurityAdvisories do
  before { allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance]) }

  let(:site) { JekyllSite.instance }

  subject(:items) { described_class.items(site) }

  it 'sorts dated items newest first and undated items last' do
    expect(items.map { |i| i['title'] }).to eq(
      [
        'Security Advisory: {{site.base_gateway}} Lua sandbox bypass',
        'Security Advisory: KONGSA-2026-0002 Admin API token leak',
        'Undated fixture advisory'
      ]
    )
  end

  it 'leaves out support documents without an advisory' do
    expect(items.map { |i| i['title'] }).not_to include('How to upgrade {{site.base_gateway}}')
  end

  it 'returns a Time for dated items and nil for undated ones' do
    expect(items.first['date']).to eq(Time.utc(2026, 6, 5))
    expect(items.last['date']).to be_nil
  end

  it 'returns the page url' do
    expect(items.first['url']).to eq('/support/security/fixture-lua-sandbox-bypass/')
  end
end
