RSpec.describe Jekyll::Drops::GatewayChangelog do
  let(:order) { %w[feature bugfix performance] }
  let(:changelog_data) do
    {
      '3.9.0.0' => {
        'kong' => [{ 'message' => 'New routing capability', 'type' => 'feature', 'scope' => 'Core' }]
      },
      '3.8' => {
        'kong' => [{ 'message' => 'Fixed a bug', 'type' => 'bugfix', 'scope' => 'Core' }],
        'kong-manager-ee' => [{ 'message' => 'Updated UI', 'type' => 'feature' }]
      }
    }
  end
  let(:site_data) do
    {
      'products' => {
        'gateway' => { 'release_dates' => { '3.9.0.0' => '2024/09/18', '3.8.0.0' => '2024/06/19' } }
      },
      'kong_plugins' => {}
    }
  end
  let(:site) { instance_double(Jekyll::Site, data: site_data, source: '/fake/source') }

  before do
    allow(Jekyll).to receive(:sites).and_return([site])
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read)
      .with('/fake/source/_changelogs/gateway.json')
      .and_return(JSON.generate(changelog_data))
    allow(File).to receive(:read)
      .with('/fake/source/_changelogs/config.yaml')
      .and_return({ 'order' => order }.to_yaml)
  end

  subject(:changelog) { described_class.new(site:) }

  describe '#versions' do
    it 'returns a Version for each unique version key' do
      expect(changelog.versions.size).to eq(2)
    end

    it { expect(changelog.versions).to all(be_a(Jekyll::Drops::GatewayChangelog::Version)) }

    it 'sorts versions newest-first by semantic version' do
      expect(changelog.versions.map(&:number)).to eq(['3.9.0.0', '3.8.0.0'])
    end
  end

  describe '#entries_by_version' do
    subject(:by_version) { changelog.entries_by_version }

    it 'normalizes short version keys to 4-part format' do
      expect(by_version.keys).to contain_exactly('3.9.0.0', '3.8.0.0')
    end

    it 'sets kong-manager-ee entries to Kong Manager scope' do
      entry = by_version['3.8.0.0'].find { |e| e['message'] == 'Updated UI' }
      expect(entry['scope']).to eq('Kong Manager')
    end

    it 'flattens all sub-key arrays for a version into one list' do
      expect(by_version['3.8.0.0'].size).to eq(2)
    end
  end

  describe '#version_to_key' do
    {
      '3.9' => '3.9.0.0',
      '3.9.1' => '3.9.1.0',
      '3.9.0.0' => '3.9.0.0',
      '3.10.0.0' => '3.10.0.0'
    }.each do |input, expected|
      it "normalizes #{input.inspect} to #{expected.inspect}" do
        expect(changelog.send(:version_to_key, input)).to eq(expected)
      end
    end
  end

  describe Jekyll::Drops::GatewayChangelog::Version do
    let(:order) { %w[feature bugfix] }
    let(:release_dates) { { '3.9.0.0' => '2024/09/18' } }
    let(:site_data) do
      {
        'products' => { 'gateway' => { 'release_dates' => release_dates } },
        'kong_plugins' => {}
      }
    end
    let(:site) { instance_double(Jekyll::Site, data: site_data, source: '/fake/source') }

    before do
      allow(Jekyll).to receive(:sites).and_return([site])
      allow(File).to receive(:read)
        .with('/fake/source/_changelogs/config.yaml')
        .and_return({ 'order' => order }.to_yaml)
    end

    let(:entries) do
      [
        { 'message' => 'New feature', 'type' => 'feature', 'scope' => 'Core' },
        { 'message' => 'Fixed a bug', 'type' => 'bugfix', 'scope' => 'Core' }
      ]
    end
    subject(:version) { described_class.new(number: '3.9.0.0', entries:) }

    describe '#number' do
      it { expect(version.number).to eq('3.9.0.0') }
    end

    describe '#release_date' do
      it 'returns the date for this version' do
        expect(version.release_date).to eq('2024/09/18')
      end

      context 'when no date is configured' do
        let(:release_dates) { {} }

        it { expect(version.release_date).to be_nil }
      end
    end

    describe '#entries_by_type' do
      it 'groups entries by type' do
        expect(version.entries_by_type.keys).to contain_exactly('feature', 'bugfix')
      end

      it 'sorts types by the configured order' do
        expect(version.entries_by_type.keys).to eq(%w[feature bugfix])
      end

      it { expect(version.entries_by_type.values).to all(be_a(Jekyll::Drops::GatewayChangelog::Entries)) }

      context 'when a type is not in the configured order' do
        let(:entries) do
          [
            { 'message' => 'X', 'type' => 'known',   'scope' => 'Core' },
            { 'message' => 'Y', 'type' => 'unknown', 'scope' => 'Core' }
          ]
        end
        let(:order) { ['known'] }

        it 'places the unknown type after all configured types' do
          expect(version.entries_by_type.keys.last).to eq('unknown')
        end
      end
    end

    describe 'plugin name substitution' do
      let(:entry) { { 'message' => +'**Rate Limiting**: Fixed a bug', 'type' => 'bugfix', 'scope' => 'Plugin' } }
      let(:entries) { [entry] }

      context 'when the plugin is found by name' do
        let(:plugin_page) do
          instance_double(Jekyll::Page,
                          data: { 'name' => 'Rate Limiting', 'slug' => 'rate-limiting' },
                          url: '/plugins/rate-limiting/')
        end
        let(:site_data) { super().merge('kong_plugins' => { 'rate-limiting' => plugin_page }) }

        it 'replaces the bold name with a markdown link' do
          version
          expect(entry['message']).to match(%r{\[rate-limiting\]\(/plugins/rate-limiting/\)})
        end
      end

      context 'when the plugin is not found' do
        it 'leaves the message unchanged' do
          version
          expect(entry['message']).to eq('**Rate Limiting**: Fixed a bug')
        end
      end

      context 'with a non-Plugin scope entry' do
        let(:entry) { { 'message' => '**some-text**: Change', 'type' => 'feature', 'scope' => 'Core' } }

        it 'does not modify the message' do
          version
          expect(entry['message']).to eq('**some-text**: Change')
        end
      end

      context 'with a Plugin entry already in link format' do
        let(:entry) do
          { 'message' => '[rate-limiting](/plugins/rate-limiting/): Fixed a bug', 'type' => 'bugfix',
            'scope' => 'Plugin' }
        end

        it 'does not modify the message' do
          version
          expect(entry['message']).to eq('[rate-limiting](/plugins/rate-limiting/): Fixed a bug')
        end
      end
    end
  end

  describe Jekyll::Drops::GatewayChangelog::Entries do
    let(:no_link) { described_class::NO_LINK }

    describe '#by_scope' do
      context 'with non-Plugin entries' do
        let(:entries) do
          [
            { 'scope' => 'Core',         'message' => 'Core change', 'type' => 'feature' },
            { 'scope' => 'Kong Manager', 'message' => 'UI change',   'type' => 'feature' }
          ]
        end
        subject(:drop) { described_class.new(entries:) }

        it 'groups entries by scope' do
          expect(drop.by_scope.keys).to contain_exactly('Core', 'Kong Manager')
        end

        it 'lists entries under their scope' do
          expect(drop.by_scope['Core'].map { |e| e['message'] }).to eq(['Core change'])
        end
      end

      context 'with Plugin entries' do
        let(:entries) do
          [{ 'scope' => 'Plugin', 'message' => '[rate-limiting](/plugins/rate-limiting/): Fixed a bug',
             'type' => 'bugfix' }]
        end
        subject(:drop) { described_class.new(entries:) }

        it 'replaces the Plugin entry list with grouped plugin data' do
          expect(drop.by_scope['Plugin']).to be_a(Hash)
        end
      end
    end

    describe '#group_plugin_entries' do
      context 'with a markdown link prefix' do
        let(:entries) do
          [
            { 'scope' => 'Plugin', 'message' => '[rate-limiting](/plugins/rate-limiting): Fixed a bug',
              'type' => 'bugfix' },
            { 'scope' => 'Plugin', 'message' => '[rate-limiting](/plugins/rate-limiting): Fixed another bug',
              'type' => 'bugfix' }
          ]
        end
        subject(:drop) { described_class.new(entries:) }

        it 'groups both entries under the link key' do
          expect(drop.group_plugin_entries['[rate-limiting](/plugins/rate-limiting):'].size).to eq(2)
        end

        it 'strips the link prefix from messages' do
          messages = drop.group_plugin_entries['[rate-limiting](/plugins/rate-limiting):'].map { |e| e['message'] }
          expect(messages).to all(start_with(' '))
          expect(messages.join).not_to include('[rate-limiting]')
        end
      end

      context 'with a bold prefix' do
        let(:entries) do
          [{ 'scope' => 'Plugin', 'message' => '**rate-limiting**: Fixed a bug', 'type' => 'bugfix' }]
        end
        subject(:drop) { described_class.new(entries:) }

        it 'groups the entry under the bold key' do
          expect(drop.group_plugin_entries['**rate-limiting**:'].size).to eq(1)
        end

        it 'strips the bold prefix from the message' do
          expect(drop.group_plugin_entries['**rate-limiting**:'].first['message']).to eq(' Fixed a bug')
        end
      end

      context 'with no recognized prefix' do
        let(:entries) do
          [{ 'scope' => 'Plugin', 'message' => 'Generic plugin change', 'type' => 'bugfix' }]
        end
        subject(:drop) { described_class.new(entries:) }

        it 'groups the entry under NO_LINK' do
          expect(drop.group_plugin_entries[no_link].size).to eq(1)
        end

        it 'does not modify the message' do
          expect(drop.group_plugin_entries[no_link].first['message']).to eq('Generic plugin change')
        end
      end

      context 'with entries from multiple plugins' do
        let(:entries) do
          [
            { 'scope' => 'Plugin', 'message' => '[acme](/plugins/acme/): Change', 'type' => 'bugfix' },
            { 'scope' => 'Plugin', 'message' => '[acl](/plugins/acl/): Change', 'type' => 'bugfix' }
          ]
        end
        subject(:drop) { described_class.new(entries:) }

        it 'sorts plugin groups alphabetically' do
          keys = drop.group_plugin_entries.keys
          expect(keys.first).to include('acl')
          expect(keys.last).to include('acme')
        end
      end
    end
  end
end
