# frozen_string_literal: true

require_relative '../../../../../app/_plugins/generators/release_info/tool'
require_relative '../../../../../app/_plugins/generators/release_info/releasable'
require_relative '../../../../../app/_plugins/drops/release'
require_relative '../../../../../app/_plugins/generators/utils/version'

RSpec.describe Jekyll::ReleaseInfo::Tool do
  let(:deck_tool) do
    YAML.load_file(File.expand_path('../../../../fixtures/app/_data/tools/deck.yml', __dir__))
  end

  let(:site_data) { { 'tools' => { 'deck' => deck_tool } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  subject(:tool) { described_class.new(site:, tool: 'deck', min_version: {}, max_version: {}) }

  describe '#available_releases' do
    it 'reads releases from the tools data path' do
      expect(tool.available_releases.map(&:number)).to eq(['2.0', '1.9', '1.8'])
    end

    it 'returns Release drop instances' do
      expect(tool.available_releases).to all(be_a(Jekyll::Drops::Release))
    end

    context 'when the tool has no releases in site data' do
      let(:site_data) { { 'tools' => {} } }

      it 'returns an empty array' do
        expect(tool.available_releases).to eq([])
      end
    end
  end

  describe '#releases' do
    context 'with no min or max version constraint' do
      it 'returns all available releases' do
        expect(tool.releases.map(&:number)).to eq(['2.0', '1.9', '1.8'])
      end
    end

    context 'with a min_version constraint' do
      subject(:tool) do
        described_class.new(site:, tool: 'deck', min_version: { 'deck' => '1.9' }, max_version: {})
      end

      it 'returns only releases at or above the minimum' do
        expect(tool.releases.map(&:number)).to eq(['2.0', '1.9'])
      end
    end

    context 'with a max_version constraint' do
      subject(:tool) do
        described_class.new(site:, tool: 'deck', min_version: {}, max_version: { 'deck' => '1.9' })
      end

      it 'returns only releases at or below the maximum' do
        expect(tool.releases.map(&:number)).to eq(['1.9', '1.8'])
      end
    end
  end

  describe '#latest_available_release' do
    it 'returns the release flagged as latest in site data' do
      expect(tool.latest_available_release.number).to eq('2.0')
    end
  end

  describe '#latest_release_in_range' do
    context 'with no constraints' do
      it 'returns the latest available release' do
        expect(tool.latest_release_in_range.number).to eq('2.0')
      end
    end

    context 'when max_version is below the latest available release' do
      subject(:tool) do
        described_class.new(site:, tool: 'deck', min_version: {}, max_version: { 'deck' => '1.9' })
      end

      it 'returns the max release' do
        expect(tool.latest_release_in_range.number).to eq('1.9')
      end
    end
  end

  describe '#deduplicated_releases' do
    it 'returns releases unchanged (no name-based deduplication for tools)' do
      expect(tool.deduplicated_releases.map(&:number)).to eq(['2.0', '1.9', '1.8'])
    end
  end

  describe '#use_release_name?' do
    it 'always returns false' do
      expect(tool.use_release_name?).to be(false)
    end
  end
end
