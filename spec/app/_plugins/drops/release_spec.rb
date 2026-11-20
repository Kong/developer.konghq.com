# frozen_string_literal: true

require_relative '../../../spec_helper'

RSpec.describe Jekyll::Drops::Release do
  subject { described_class.new(release_hash) }

  describe '#version' do
    context 'when the release entry has a version key' do
      let(:release_hash) { { 'release' => '2.14', 'version' => '2.14.3' } }

      it 'returns the patch version' do
        expect(subject.version).to eq('2.14.3')
      end
    end

    context 'when the release entry has no version key' do
      let(:release_hash) { { 'release' => '3.15' } }

      it 'returns nil' do
        expect(subject.version).to be_nil
      end
    end

    it 'is reachable from Liquid' do
      template = Liquid::Template.parse('{{release.version}}')
      release  = described_class.new({ 'release' => '2.14', 'version' => '2.14.3' })

      expect(template.render('release' => release)).to eq('2.14.3')
    end
  end

  describe '#to_s' do
    let(:release_hash) { { 'release' => '2.14', 'version' => '2.14.3' } }

    it 'still returns the minor release' do
      expect(subject.to_s).to eq('2.14')
    end
  end
end
