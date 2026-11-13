# frozen_string_literal: true

require_relative '../../../spec_helper'

RSpec.describe Jekyll::SecurityAdvisoriesSort do
  # The filter module is included into Liquid's context, so call it through a
  # plain object extended with it — the same interface Liquid uses.
  class FilterHost
    include Jekyll::SecurityAdvisoriesSort
  end

  def sort(advisories)
    FilterHost.new.security_advisories_sort(advisories)
  end

  def advisory(title, published)
    { 'title' => title, 'advisory' => { 'published' => published } }
  end

  # Nineteen advisories sharing one date, titled 01..19 — the shape of the
  # real 2026-08-10 cluster, which Liquid's own sort mis-handles.
  let(:tied) do
    (1..19).map { |n| advisory(format('Advisory %02d', n), '2026-08-10') }
  end

  describe '#security_advisories_sort' do
    it 'orders same-date advisories by title' do
      sorted = sort(tied)
      expect(sorted.map { |a| a['title'] }).to eq(
        (1..19).map { |n| format('Advisory %02d', n) }
      )
    end

    it 'returns the same order for several shuffled input orders' do
      expected = sort(tied).map { |a| a['title'] }

      [tied.rotate(7), tied.reverse, tied.shuffle(random: Random.new(42)), tied.rotate(1)].each do |input|
        expect(sort(input).map { |a| a['title'] }).to eq(expected)
      end
    end

    it 'orders distinct dates newest first' do
      input = [
        advisory('Older', '2024-04-11'),
        advisory('Newer', '2026-10-13')
      ]
      expect(sort(input).map { |a| a['title'] }).to eq(%w[Newer Older])
    end
  end
end
