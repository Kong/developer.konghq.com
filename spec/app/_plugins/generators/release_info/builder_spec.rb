# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::ReleaseInfo::Builder do
  let(:gateway_releases) do
    [
      { 'release' => '3.10', 'latest' => true },
      { 'release' => '3.9' },
      { 'release' => '2.1' },
      { 'release' => '2.0' }
    ]
  end
  let(:tool_releases) do
    [
      { 'release' => '2.0', 'latest' => true },
      { 'release' => '1.9' }
    ]
  end
  let(:site_data) do
    {
      'products' => { 'gateway' => { 'releases' => gateway_releases } },
      'tools' => { 'deck' => { 'releases' => tool_releases } }
    }
  end
  let(:site) { instance_double(Jekyll::Site, data: site_data) }
  let(:page) { instance_double('Jekyll::Page', data: page_data) }

  subject(:result) { described_class.run(page) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  describe '.run' do
    context 'with a product page and no major_version in frontmatter' do
      let(:page_data) { { 'products' => ['gateway'] } }

      it 'returns a Product scoped to the current major (release flagged latest)' do
        expect(result).to be_a(Jekyll::ReleaseInfo::Product)
        expect(result.available_releases.map(&:number)).to eq(['3.10', '3.9'])
      end
    end

    context 'with a product page and an explicit major_version' do
      let(:page_data) { { 'products' => ['gateway'], 'major_version' => { 'gateway' => 2 } } }

      it 'returns a Product scoped to the requested major' do
        expect(result.available_releases.map(&:number)).to eq(['2.1', '2.0'])
      end
    end

    context 'with a major_version that is not represented in releases' do
      let(:page_data) { { 'products' => ['gateway'], 'major_version' => { 'gateway' => 4 } } }

      it 'raises InvalidMajorVersion' do
        expect { result }.to raise_error(Jekyll::ReleaseInfo::MajorResolver::InvalidMajorVersion)
      end
    end

    context 'with a major_version that disagrees with min_version' do
      let(:page_data) do
        {
          'products' => ['gateway'],
          'major_version' => { 'gateway' => 2 },
          'min_version' => { 'gateway' => '3.4' }
        }
      end

      it 'raises InvalidMajorVersion' do
        expect { result }.to raise_error(Jekyll::ReleaseInfo::MajorResolver::InvalidMajorVersion)
      end
    end

    context 'with min_version belonging to the current major and no major_version' do
      let(:page_data) { { 'products' => ['gateway'], 'min_version' => { 'gateway' => '3.10' } } }

      it 'returns a Product scoped to the current major and respects min_version' do
        expect(result.releases.map(&:number)).to eq(['3.10'])
      end
    end

    context 'with a tool page (no products)' do
      let(:page_data) { { 'tools' => ['deck'] } }

      it 'returns a Tool without invoking the major resolver' do
        expect(result).to be_a(Jekyll::ReleaseInfo::Tool)
        expect(result.available_releases.map(&:number)).to eq(['2.0', '1.9'])
      end
    end
  end
end
