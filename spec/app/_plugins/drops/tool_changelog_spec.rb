# frozen_string_literal: true

RSpec.describe Jekyll::Drops::ToolChangelog do
  before { allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance]) }

  let(:changelog) { Jekyll::Drops::ToolChangelog.new(site: JekyllSite.instance, tool: 'kong-harnesses') }

  describe '#versions' do
    it 'returns one Version per version key' do
      expect(changelog.versions.map(&:number)).to eq(['0.19.0', '0.18.0', '0.17.0'])
    end

    it 'sorts versions newest-first by semantic version' do
      expect(changelog.versions.first.number).to eq('0.19.0')
      expect(changelog.versions.last.number).to eq('0.17.0')
    end

    it { expect(changelog.versions).to all(be_a(Jekyll::Drops::ToolChangelog::Version)) }
  end

  describe Jekyll::Drops::ToolChangelog::Version do
    let(:populated_version) { changelog.versions.find { |v| v.number == '0.19.0' } }
    let(:partial_version) { changelog.versions.find { |v| v.number == '0.18.0' } }

    describe '#release_date' do
      it 'reads the date from the tool data file' do
        expect(populated_version.release_date).to eq('2026/11/25')
        expect(partial_version.release_date).to eq('2026/11/21')
      end
    end

    describe '#entries_by_type' do
      it 'groups entries by type' do
        expect(populated_version.entries_by_type.keys).to contain_exactly('feature', 'bugfix', 'Breaking Change',
                                                                    'dependencies')
      end

      it 'orders the known types by config.yaml, and the unknown type last' do
        expect(populated_version.entries_by_type.keys).to eq(['Breaking Change', 'feature', 'bugfix', 'dependencies'])
      end

      it 'includes only the types a version has' do
        expect(partial_version.entries_by_type.keys).to eq(%w[feature performance])
      end

      it 'lists the messages under their type' do
        expect(partial_version.entries_by_type['feature'].map { |e| e['message'] }).to eq(['add the statusline command'])
      end
    end
  end
end
