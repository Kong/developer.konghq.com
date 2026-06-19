# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::Data::LlmMetadata do
  let(:site_data) do
    {
      'products' => {
        'gateway' => {
          'name' => 'Kong Gateway',
          'tiers' => {
            'free' => { 'text' => 'Free' },
            'enterprise' => { 'text' => 'Enterprise' }
          }
        },
        'ai-gateway' => {
          'name' => 'Kong AI Gateway',
          'previous_major_url_segment' => 'v<major>',
          'releases' => [
            { 'release' => '2.0', 'latest' => true, 'version' => '2.0.0', 'name' => 'v2' },
            { 'release' => '1.0' }
          ]
        }

      },
      'tools' => { 'deck' => { 'name' => 'decK' } }
    }
  end
  let(:sitemap_exclusions) { [] }
  let(:site) do
    instance_double(Jekyll::Site,
                    data: site_data,
                    config: { 'sitemap' => { 'exclude' => sitemap_exclusions } })
  end
  let(:page_url) { '/gateway/install/' }
  let(:base_page_data) do
    {
      'llm_title' => 'Install Kong Gateway',
      'description' => 'How to install Kong Gateway',
      'content_type' => 'how_to',
      'products' => ['gateway'],
      'canonical?' => true
    }
  end
  let(:page_data) { base_page_data }
  let(:page) { instance_double(Jekyll::Page, data: page_data, url: page_url) }

  subject { described_class.new(site:, page:) }

  describe '#process' do
    context 'when URL starts with /assets/' do
      let(:page_url) { '/assets/mesh/test.yaml' }
      it { expect(subject.process).to be_nil }
    end

    context 'when layout is none' do
      let(:page_data) { base_page_data.merge('layout' => 'none') }
      it { expect(subject.process).to be_nil }
    end

    context 'when URL is in sitemap exclusions' do
      let(:sitemap_exclusions) { [page_url] }
      it { expect(subject.process).to be_nil }
    end

    context 'when processable' do
      before { subject.process }
      it { expect(page.data['llm_frontmatter']).not_to be_nil }
    end
  end

  describe '#frontmatter' do
    let(:parsed) { YAML.safe_load(subject.frontmatter) }

    it 'sets title from llm_title' do
      expect(parsed['title']).to eq('Install Kong Gateway')
    end

    it 'sets description' do
      expect(parsed['description']).to eq('How to install Kong Gateway')
    end

    it 'sets url from page url' do
      expect(parsed['url']).to eq('/gateway/install/')
    end

    it 'sets content_type' do
      expect(parsed['content_type']).to eq('how_to')
    end

    it 'resolves product slugs to names' do
      expect(parsed['products']).to eq(['Kong Gateway'])
    end

    it 'sets canonical from canonical?' do
      expect(parsed['canonical']).to be true
    end

    it 'compacts nil fields' do
      expect(parsed.keys).not_to include('third_party', 'tier', 'tools', 'beta', 'canonical_url')
    end

    context 'when canonical_url is present' do
      let(:page_data) { base_page_data.merge('canonical_url' => '/gateway/install/') }
      it { expect(parsed['canonical_url']).to eq('/gateway/install/') }
    end

    context 'when canonical? is false' do
      let(:page_data) { base_page_data.merge('canonical?' => false) }
      it { expect(parsed['canonical']).to be false }
    end

    context 'when canonical? is nil' do
      let(:page_data) { base_page_data.reject { |k, _| k == 'canonical?' } }
      it { expect(parsed.keys).not_to include('canonical') }
    end

    context 'when tags are present' do
      let(:page_data) { base_page_data.merge('tags' => %w[security authentication]) }
      it { expect(parsed['tags']).to eq(%w[security authentication]) }
    end

    context 'when tags are absent' do
      it { expect(parsed.keys).not_to include('tags') }
    end

    context 'when works_on is present' do
      let(:page_data) { base_page_data.merge('works_on' => %w[db-less traditional]) }
      it { expect(parsed['works_on']).to eq(%w[db-less traditional]) }
    end

    context 'when works_on is absent' do
      it { expect(parsed.keys).not_to include('works_on') }
    end

    context 'when tiers are present' do
      let(:page_data) { base_page_data.merge('tiers' => { 'gateway' => 'enterprise' }) }
      it { expect(parsed['tiers']).to eq({ 'Kong Gateway' => 'Enterprise' }) }
    end

    context 'when major_version is present' do
      let(:page_data) { base_page_data.merge('major_version' => { 'ai-gateway' => 1 }) }
      it { expect(parsed['major_version']).to eq({ 'Kong AI Gateway' => 'v1' }) }
    end

    context 'when plugin? and overview?' do
      let(:page_data) do
        base_page_data.merge(
          'plugin?' => true, 'overview?' => true,
          'topologies' => ['on-prem'], 'publisher' => 'Kong',
          'compatible_protocols' => ['http'], 'categories' => ['security']
        )
      end

      it 'merges plugin metadata' do
        expect(parsed['topologies']).to eq(['on-prem'])
        expect(parsed['publisher']).to eq('Kong')
        expect(parsed['compatible_protocols']).to eq(['http'])
        expect(parsed['categories']).to eq(['security'])
      end
    end

    context 'when content_type is skill' do
      let(:page_data) do
        base_page_data.merge(
          'content_type' => 'skill',
          'source_url' => 'https://example.com/skill',
          'plugin_source_url' => 'https://example.com/plugin'
        )
      end

      it 'merges skill metadata' do
        expect(parsed['source']).to eq('https://example.com/skill')
        expect(parsed['owning_plugin']).to eq('https://example.com/plugin')
      end
    end
  end

  describe '#resolve_names' do
    it 'returns nil when slugs is nil' do
      expect(subject.resolve_names(nil, 'products')).to be_nil
    end

    it 'returns nil when slugs is empty' do
      expect(subject.resolve_names([], 'products')).to be_nil
    end

    it 'resolves slugs to names from site data' do
      expect(subject.resolve_names(['gateway'], 'products')).to eq(['Kong Gateway'])
    end

    it 'resolves tool slugs' do
      expect(subject.resolve_names(['deck'], 'tools')).to eq(['decK'])
    end
  end

  describe '#resolve_tiers' do
    it 'returns nil when tiers is nil' do
      expect(subject.resolve_tiers(nil)).to be_nil
    end

    it 'returns nil when tiers is empty' do
      expect(subject.resolve_tiers({})).to be_nil
    end

    it 'maps product slug and tier key to display names' do
      expect(subject.resolve_tiers({ 'gateway' => 'enterprise' })).to eq({ 'Kong Gateway' => 'Enterprise' })
    end

    it 'falls back to the tier key when tier text is not found' do
      expect(subject.resolve_tiers({ 'gateway' => 'unknown_tier' })).to eq({ 'Kong Gateway' => 'unknown_tier' })
    end
  end

  describe '#plugin_metadata' do
    context 'when plugin? and overview?' do
      let(:page_url) { '/plugins/rate-limiting/' }

      let(:page_data) do
        base_page_data.merge(
          'plugin?' => true, 'overview?' => true,
          'topologies' => ['on-prem'], 'publisher' => 'Kong',
          'compatible_protocols' => ['http'], 'categories' => ['security']
        )
      end

      it 'returns plugin fields' do
        expect(subject.plugin_metadata).to eq({
                                                'topologies' => ['on-prem'],
                                                'publisher' => 'Kong',
                                                'compatible_protocols' => ['http'],
                                                'categories' => ['security']
                                              })
      end
    end

    context 'when plugin? but not overview?' do
      let(:page_url) { '/plugins/rate-limiting/reference' }
      let(:page_data) { base_page_data.merge('plugin?' => true, 'reference?' => true) }
      it { expect(subject.plugin_metadata).to eq({}) }
    end

    context 'when neither plugin? nor overview?' do
      it { expect(subject.plugin_metadata).to eq({}) }
    end
  end

  describe '#skill_metadata' do
    context 'when content_type is skill' do
      let(:page_url) { '/skills/test/' }
      let(:page_data) do
        base_page_data.merge(
          'content_type' => 'skill',
          'source_url' => 'https://example.com/skill',
          'plugin_source_url' => 'https://example.com/plugin'
        )
      end

      it 'returns source and owning_plugin' do
        expect(subject.skill_metadata).to eq({
                                               'source' => 'https://example.com/skill',
                                               'owning_plugin' => 'https://example.com/plugin'
                                             })
      end
    end

    context 'when content_type is not skill' do
      let(:page_url) { '/skills/install/' }

      it { expect(subject.skill_metadata).to eq({}) }
    end
  end
end
