# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::ReleaseInfo::MajorResolver do
  let(:releases) do
    [
      { 'release' => '3.10', 'latest' => true },
      { 'release' => '3.9' },
      { 'release' => '2.1' },
      { 'release' => '2.0' }
    ]
  end
  let(:site_data) { { 'products' => { 'gateway' => { 'releases' => releases } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  subject do
    described_class.new(
      site:,
      product: 'gateway',
      page_major_version: page_major_version,
      min_version: min_version,
      max_version: max_version
    )
  end

  let(:page_major_version) { nil }
  let(:min_version) { nil }
  let(:max_version) { nil }

  describe '#resolve' do
    context 'when the product has no releases at all' do
      let(:site_data) { { 'products' => { 'gateway' => {} } } }

      it 'returns nil without raising' do
        expect(subject.resolve).to be_nil
      end
    end

    context 'with no page-level major_version' do
      it 'returns the major of the release flagged latest' do
        expect(subject.resolve).to eq(3)
      end
    end

    context 'when the product has no release flagged latest' do
      let(:releases) { [{ 'release' => '3.10' }, { 'release' => '3.9' }] }

      it 'raises InvalidMajorVersion' do
        expect { subject.resolve }.to raise_error(
          described_class::InvalidMajorVersion,
          /No release flagged `latest: true` for product `gateway`/
        )
      end
    end

    context 'with an explicit major_version ' do
      context 'with an explicit major_version that matches an existing major' do
        let(:page_major_version) { { 'gateway' => 2 } }

        it 'returns the requested major' do
          expect(subject.resolve).to eq(2)
        end
      end

      context 'with an explicit major_version for a different product' do
        let(:page_major_version) { { 'mesh' => 2 } }

        it 'falls back to the current major for first product in the `products` list' do
          expect(subject.resolve).to eq(3)
        end
      end

      context 'with an explicit major_version that does not exist' do
        let(:page_major_version) { { 'gateway' => 4 } }

        it 'raises InvalidMajorVersion naming the available majors' do
          expect { subject.resolve }.to raise_error(
            described_class::InvalidMajorVersion,
            /major_version\.gateway=4.*\[3, 2\]/
          )
        end
      end

      context 'when min_version belongs to a higher major than the explicitly requested major' do
        let(:page_major_version) { { 'gateway' => 2 } }
        let(:min_version) { '3.4' }

        it 'raises InvalidMajorVersion' do
          expect { subject.resolve }.to raise_error(
            described_class::InvalidMajorVersion,
            /min_version\.gateway=3\.4.*resolved major is 2/
          )
        end
      end

      context 'when min_version belongs to a lower major than the explicitly requested major' do
        let(:page_major_version) { { 'gateway' => 3 } }
        let(:min_version) { '2.1' }

        it 'returns the resolved major without raising' do
          expect(subject.resolve).to eq(3)
        end
      end

      context 'when min_version disagrees with the current major and no major_version is requested' do
        let(:page_major_version) { nil }
        let(:min_version) { '2.1' }

        it 'returns the current major without raising' do
          expect(subject.resolve).to eq(3)
        end
      end

      context 'when max_version belongs to a different major than the resolved major' do
        let(:page_major_version) { { 'gateway' => 2 } }
        let(:max_version) { '3.9' }

        it 'raises InvalidMajorVersion' do
          expect { subject.resolve }.to raise_error(
            described_class::InvalidMajorVersion,
            /max_version\.gateway=3\.9.*resolved major is 2/
          )
        end
      end

      context 'when min_version and max_version both belong to the resolved major' do
        let(:page_major_version) { { 'gateway' => 3 } }
        let(:min_version) { '3.9' }
        let(:max_version) { '3.10' }

        it 'returns the resolved major' do
          expect(subject.resolve).to eq(3)
        end
      end
    end
  end
end
