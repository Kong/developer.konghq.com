# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::ReleaseInfo::Product do
  let(:gateway_product) do
    YAML.load_file(File.expand_path('../../../../fixtures/app/_data/products/gateway.yml', __dir__))
  end
  let(:event_gateway_product) do
    YAML.load_file(File.expand_path('../../../../fixtures/app/_data/products/event-gateway.yml', __dir__))
  end

  let(:site_data) do
    { 'products' => { 'gateway' => gateway_product, 'event-gateway' => event_gateway_product } }
  end

  let(:site) { instance_double(Jekyll::Site, data: site_data) }
  let(:scoped_site_data) do
    {
      'products' => {
        'gateway' => {
          'releases' => [
            { 'release' => '3.10', 'latest' => true },
            { 'release' => '3.9' },
            { 'release' => '2.1' },
            { 'release' => '2.0' }
          ]
        }
      }
    }
  end

  let(:min_version) { {} }
  let(:max_version) { {} }
  let(:major) { nil }
  let(:product) { 'gateway' }

  subject { described_class.new(site:, product:, min_version:, max_version:, major:) }

  describe '#available_releases' do
    context 'without a major: scope' do
      it 'returns all releases from site data regardless of version range' do
        expect(subject.available_releases.map(&:number)).to eq(['3.10', '3.9'])
      end

      it 'returns Release drop instances' do
        expect(subject.available_releases).to all(be_a(Jekyll::Drops::Release))
      end
    end

    describe 'with a major: scope' do
      let(:site_data) { scoped_site_data }

      context 'when scoped to the current major' do
        let(:major) { 3 }

        it 'only exposes releases from that major' do
          expect(subject.available_releases.map(&:number)).to eq(['3.10', '3.9'])
        end
      end

      context 'when scoped to a previous major' do
        let(:major) { 2 }

        it 'only exposes releases from that major' do
          expect(subject.available_releases.map(&:number)).to eq(['2.1', '2.0'])
        end
      end
    end
  end

  describe '#releases' do
    context 'without a major: scope' do
      context 'with no min or max version constraint' do
        it 'returns all available releases' do
          expect(subject.releases.map(&:number)).to eq(['3.10', '3.9'])
        end
      end

      context 'with a min_version constraint' do
        let(:min_version) { { 'gateway' => '3.10' } }

        it 'returns only releases at or above the minimum' do
          expect(subject.releases.map(&:number)).to eq(['3.10'])
        end
      end

      context 'with a max_version constraint' do
        let(:max_version) { { 'gateway' => '3.9' } }

        it 'returns only releases at or below the maximum' do
          expect(subject.releases.map(&:number)).to eq(['3.9'])
        end
      end
    end

    describe 'with a major: scope' do
      let(:site_data) { scoped_site_data }

      context 'when scoped to the current major' do
        let(:major) { 3 }
        it 'only exposes releases from that major in releases' do
          expect(subject.releases.map(&:number)).to eq(['3.10', '3.9'])
        end
      end

      context 'when scoped to a previous major' do
        let(:major) { 2 }
        it 'only exposes releases from that major in releases' do
          expect(subject.releases.map(&:number)).to eq(['2.1', '2.0'])
        end
      end
    end
  end

  describe '#latest_available_release' do
    context 'without a major: scope' do
      it 'returns the release flagged as latest in site data' do
        expect(subject.latest_available_release.number).to eq('3.10')
      end
    end

    describe 'with a major: scope' do
      let(:site_data) { scoped_site_data }

      context 'when scoped to the current major' do
        let(:major) { 3 }
        it 'returns the release with the highest number in that major' do
          expect(subject.latest_available_release.number).to eq('3.10')
        end
      end

      context 'when scoped to a previous major' do
        let(:major) { 2 }
        it 'returns the release with the highest number in that major' do
          expect(subject.latest_available_release.number).to eq('2.1')
        end
      end
    end
  end

  describe '#min_release' do
    context 'when no min_version is set' do
      it 'returns nil' do
        expect(subject.min_release).to be_nil
      end
    end

    context 'when min_version matches a release' do
      let(:min_version) { { 'gateway' => '3.9' } }

      it 'returns the matching release' do
        expect(subject.min_release.number).to eq('3.9')
      end
    end
  end

  describe '#max_release' do
    context 'when no max_version is set' do
      it 'returns nil' do
        expect(subject.max_release).to be_nil
      end
    end

    context 'when max_version matches a release' do
      let(:max_version) { { 'gateway' => '3.9' } }

      it 'returns the matching release' do
        expect(subject.max_release.number).to eq('3.9')
      end
    end
  end

  describe '#latest_release_in_range' do
    context 'without a major: scope' do
      context 'with no constraints' do
        it 'returns the latest available release' do
          expect(subject.latest_release_in_range.number).to eq('3.10')
        end
      end

      context 'when max_version is below the latest available release' do
        let(:max_version) { { 'gateway' => '3.9' } }

        it 'returns the max release' do
          expect(subject.latest_release_in_range.number).to eq('3.9')
        end
      end

      context 'when min_version exceeds the latest available release (future page)' do
        let(:site_data) do
          {
            'products' => {
              'gateway' => {
                'releases' => [
                  { 'release' => '3.11' },
                  { 'release' => '3.10', 'latest' => true },
                  { 'release' => '3.9' }
                ]
              }
            }
          }
        end

        let(:min_version) { { 'gateway' => '3.11' } }

        it 'returns the min release' do
          expect(subject.latest_release_in_range.number).to eq('3.11')
        end
      end
    end
    describe 'with a major: scope' do
      let(:site_data) { scoped_site_data }

      context 'when scoped to the current major' do
        let(:major) { 3 }
        it 'returns the latest available release in the range within the major' do
          expect(subject.latest_release_in_range.number).to eq('3.10')
        end
      end

      context 'when scoped to a previous major' do
        let(:major) { 2 }
        it 'returns the latest available release in the range within the major' do
          expect(subject.latest_release_in_range.number).to eq('2.1')
        end
      end
    end
  end

  describe '#unreleased?' do
    context 'when latest_release_in_range equals latest_available_release' do
      it 'returns false' do
        expect(subject.unreleased?).to be(false)
      end
    end

    context 'when max_version caps below the latest available release' do
      let(:max_version) { { 'gateway' => '3.9' } }

      it 'returns true' do
        expect(subject.unreleased?).to be(true)
      end
    end
  end

  describe '#deduplicated_releases' do
    context 'for a non-event-gateway product' do
      it 'returns releases unchanged' do
        expect(subject.deduplicated_releases.map(&:number)).to eq(['3.10', '3.9'])
      end
    end

    context 'for event-gateway' do
      let(:product) { 'event-gateway' }

      it 'deduplicates by name, keeping the highest release per name' do
        expect(subject.deduplicated_releases.map(&:number)).to eq(['1.1.0'])
      end
    end
  end

  describe '#use_release_name?' do
    context 'for a non-event-gateway product' do
      it 'returns false' do
        expect(subject.use_release_name?).to be(false)
      end
    end

    context 'for event-gateway' do
      let(:product) { 'event-gateway' }

      it 'returns true' do
        expect(subject.use_release_name?).to be(true)
      end
    end
  end
end
