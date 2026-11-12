# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::Feeds::Sources::SecurityAdvisories do # rubocop:disable Metrics/BlockLength
  def doc(title, advisory)
    data = { 'title' => title }
    data['advisory'] = advisory unless advisory.nil?
    instance_double(Jekyll::Document, data: data, url: "/support/security/#{title.downcase}/")
  end

  let(:docs) do
    [
      doc('Old', { 'published' => '2024-04-11' }),
      doc('Undated', {}),
      doc('New', { 'published' => '2026-10-13' }),
      doc('Article', nil)
    ]
  end
  let(:site) { instance_double(Jekyll::Site, collections: { 'support' => instance_double(Jekyll::Collection, docs: docs) }) }

  subject(:items) { described_class.items(site) }

  it 'sorts dated items newest first and undated items last' do
    expect(items.map { |i| i['title'] }).to eq(%w[New Old Undated])
  end

  it 'leaves out docs without advisory' do
    expect(items.map { |i| i['title'] }).not_to include('Article')
  end

  it 'returns a Time for dated items and nil for undated ones' do
    expect(items.first['date']).to eq(Time.utc(2026, 10, 13))
    expect(items.last['date']).to be_nil
  end

  it 'returns the page url' do
    expect(items.first['url']).to eq('/support/security/new/')
  end
end
