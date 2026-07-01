# frozen_string_literal: true

require_relative '../../../spec_helper'
require_relative '../../../../app/_plugins/generators/indices'

RSpec.describe Jekyll::IndexGenerator do
  subject(:generator) { described_class.new }

  describe '#normalize_paths' do
    let(:index) do
      {
        'groups' => [
          {
            'sections' => [
              {
                'title' => 'Section 1',
                'items' => [
                  { 'path' => 1234 },
                  { 'path' => '/string-path/' },
                  { 'title' => 'no-path item' }
                ],
                'not_match' => [
                  { 'path' => 5678 }
                ]
              }
            ]
          }
        ]
      }
    end

    subject(:result) { generator.normalize_paths(index) }

    it 'converts numeric item paths to strings' do
      expect(result['groups'][0]['sections'][0]['items'][0]['path']).to eq('1234')
    end

    it 'leaves string paths unchanged' do
      expect(result['groups'][0]['sections'][0]['items'][1]['path']).to eq('/string-path/')
    end

    it 'converts not_match paths to strings' do
      expect(result['groups'][0]['sections'][0]['not_match'][0]['path']).to eq('5678')
    end

    it 'leaves items without a path key unchanged' do
      expect(result['groups'][0]['sections'][0]['items'][2]).to eq({ 'title' => 'no-path item' })
    end
  end

  describe '#process_auto_exclude' do
    context 'with auto_exclude: true' do
      let(:index) do
        {
          'groups' => [
            {
              'sections' => [
                { 'title' => 'A', 'items' => [{ 'path' => '/a/' }] },
                { 'title' => 'B', 'auto_exclude' => true, 'items' => [{ 'path' => '/b/' }] },
                { 'title' => 'C', 'items' => [{ 'path' => '/c/' }] }
              ]
            }
          ]
        }
      end

      it 'adds items from all other sections to not_match' do
        result = generator.process_auto_exclude(index)
        not_match_paths = result['groups'][0]['sections'][1]['not_match'].map { |i| i['path'] }
        expect(not_match_paths).to contain_exactly('/a/', '/c/')
      end
    end

    context 'with auto_exclude_group: true' do
      let(:index) do
        {
          'groups' => [
            {
              'sections' => [
                { 'title' => 'A', 'items' => [{ 'path' => '/a/' }] },
                { 'title' => 'B', 'auto_exclude_group' => true, 'items' => [{ 'path' => '/b/' }] }
              ]
            },
            {
              'sections' => [
                { 'title' => 'C', 'items' => [{ 'path' => '/c/' }] }
              ]
            }
          ]
        }
      end

      it 'excludes only items from the same group' do
        result = generator.process_auto_exclude(index)
        not_match_paths = result['groups'][0]['sections'][1]['not_match'].map { |i| i['path'] }
        expect(not_match_paths).to contain_exactly('/a/')
      end

      it 'does not include items from other groups' do
        result = generator.process_auto_exclude(index)
        not_match_paths = result['groups'][0]['sections'][1]['not_match'].map { |i| i['path'] }
        expect(not_match_paths).not_to include('/c/')
      end
    end

    context 'when exclusion list has duplicate paths' do
      let(:index) do
        {
          'groups' => [
            {
              'sections' => [
                { 'title' => 'A', 'items' => [{ 'path' => '/dup/' }] },
                { 'title' => 'A2', 'items' => [{ 'path' => '/dup/' }] },
                { 'title' => 'B', 'auto_exclude' => true, 'items' => [{ 'path' => '/b/' }] }
              ]
            }
          ]
        }
      end

      it 'deduplicates by path' do
        result = generator.process_auto_exclude(index)
        not_match = result['groups'][0]['sections'][2]['not_match']
        expect(not_match.select { |i| i['path'] == '/dup/' }.count).to eq(1)
      end
    end

    context 'when existing not_match entries are present' do
      let(:index) do
        {
          'groups' => [
            {
              'sections' => [
                { 'title' => 'A', 'items' => [{ 'path' => '/a/' }] },
                {
                  'title' => 'B',
                  'auto_exclude' => true,
                  'items' => [{ 'path' => '/b/' }],
                  'not_match' => [{ 'path' => '/existing/' }]
                }
              ]
            }
          ]
        }
      end

      it 'merges with existing not_match entries' do
        result = generator.process_auto_exclude(index)
        not_match_paths = result['groups'][0]['sections'][1]['not_match'].map { |i| i['path'] }
        expect(not_match_paths).to include('/existing/', '/a/')
      end
    end

    context 'with no auto_exclude sections' do
      let(:index) do
        {
          'groups' => [
            { 'sections' => [{ 'title' => 'A', 'items' => [{ 'path' => '/a/' }] }] }
          ]
        }
      end

      it { expect(generator.process_auto_exclude(index)).to eq(index) }
    end
  end

  describe '#page_is_versioned' do
    context 'when page has non-empty releases and is not canonical' do
      let(:page) { instance_double(Jekyll::Page, data: { 'releases' => ['1.0'], 'canonical?' => false }) }

      it { expect(generator.page_is_versioned(page)).to be(true) }
    end

    context 'when releases is nil' do
      let(:page) { instance_double(Jekyll::Page, data: { 'releases' => nil }) }

      it { expect(generator.page_is_versioned(page)).to be_falsy }
    end

    context 'when releases is empty' do
      let(:page) { instance_double(Jekyll::Page, data: { 'releases' => [] }) }

      it { expect(generator.page_is_versioned(page)).to be_falsy }
    end

    context 'when page is canonical' do
      let(:page) { instance_double(Jekyll::Page, data: { 'releases' => ['1.0'], 'canonical?' => true }) }

      it { expect(generator.page_is_versioned(page)).to be_falsy }
    end
  end

  describe '#how_to_search_link' do
    it 'builds a URL with a products param' do
      expect(generator.how_to_search_link({ 'products' => ['gateway'], 'title' => 'ignored' }))
        .to eq('/how-to?products=gateway')
    end

    it 'builds a URL with multiple recognized params' do
      result = generator.how_to_search_link({ 'products' => ['gateway'], 'tags' => ['security'] })
      expect(result).to include('products=gateway')
      expect(result).to include('tags=security')
    end

    it 'raises when no recognized search params are present' do
      expect { generator.how_to_search_link({ 'title' => 'only title' }) }
        .to raise_error(/No search URL found in config/)
    end
  end

  describe '#add_entry' do
    let(:sections) { { 'Overview' => { 'pages' => [] } } }
    let(:seen) { {} }

    before { generator.instance_variable_set(:@sections, sections) }

    context 'with a Jekyll page object' do
      let(:page) { instance_double(Jekyll::Page, url: '/gateway/') }

      it 'appends the wrapped entry to the section' do
        generator.add_entry('Overview', page, 0, false, seen)
        expect(sections['Overview']['pages']).to eq([{ 'page' => page, 'match_index' => 0 }])
      end

      it 'marks the url as seen' do
        generator.add_entry('Overview', page, 0, false, seen)
        expect(seen).to eq({ '/gateway/' => true })
      end
    end

    context 'with a hash entry' do
      let(:page) { { 'url' => '/search/', 'title' => 'Search' } }

      it 'appends the wrapped hash entry' do
        generator.add_entry('Overview', page, 1, false, seen)
        expect(sections['Overview']['pages']).to eq([{ 'page' => page, 'match_index' => 1 }])
      end
    end

    context 'when url is already seen and allow_duplicates is false' do
      let(:page) { instance_double(Jekyll::Page, url: '/gateway/') }

      before { seen['/gateway/'] = true }

      it 'skips the entry' do
        generator.add_entry('Overview', page, 0, false, seen)
        expect(sections['Overview']['pages']).to be_empty
      end
    end

    context 'when url is already seen and allow_duplicates is true' do
      let(:page) { instance_double(Jekyll::Page, url: '/gateway/') }

      before { seen['/gateway/'] = true }

      it 'adds the entry' do
        generator.add_entry('Overview', page, 0, true, seen)
        expect(sections['Overview']['pages'].length).to eq(1)
      end
    end
  end

  describe '#add_path' do
    let(:sections) { { 'Overview' => { 'pages' => [] } } }
    let(:seen) { {} }

    before { generator.instance_variable_set(:@sections, sections) }

    context 'when path matches exactly' do
      let(:page) { instance_double(Jekyll::Page, url: '/gateway/', data: {}) }

      it 'adds the page to the section' do
        generator.add_path(page, 'Overview', { 'path' => '/gateway/' }, nil, 0, false, seen)
        expect(sections['Overview']['pages'].length).to eq(1)
      end
    end

    context 'when path does not match' do
      let(:page) { instance_double(Jekyll::Page, url: '/other/', data: {}) }

      it 'does not add the page' do
        generator.add_path(page, 'Overview', { 'path' => '/gateway/' }, nil, 0, false, seen)
        expect(sections['Overview']['pages']).to be_empty
      end
    end

    context 'when path matches a glob pattern' do
      let(:page) { instance_double(Jekyll::Page, url: '/gateway/install/docker/', data: {}) }

      it 'adds the page' do
        generator.add_path(page, 'Overview', { 'path' => '/gateway/install/**/*' }, nil, 0, false, seen)
        expect(sections['Overview']['pages'].length).to eq(1)
      end
    end

    context 'when page url is in not_match list' do
      let(:page) { instance_double(Jekyll::Page, url: '/gateway/', data: {}) }
      let(:not_match) { [{ 'path' => '/gateway/' }] }

      it 'does not add the page' do
        generator.add_path(page, 'Overview', { 'path' => '/gateway/' }, not_match, 0, false, seen)
        expect(sections['Overview']['pages']).to be_empty
      end
    end

    context 'when not_match item has no path key' do
      let(:page) { instance_double(Jekyll::Page, url: '/gateway/', data: {}) }
      let(:not_match) { [{ 'title' => 'no path' }] }

      it 'adds the page (not_match entry is ignored)' do
        generator.add_path(page, 'Overview', { 'path' => '/gateway/' }, not_match, 0, false, seen)
        expect(sections['Overview']['pages'].length).to eq(1)
      end
    end
  end

  describe '#sort_sections!' do
    before do
      generator.instance_variable_set(:@sections, {
        'Section A' => {
          'pages' => [
            { 'page' => { 'title' => 'Zebra', 'weight' => nil }, 'match_index' => 1 },
            { 'page' => { 'title' => 'Apple', 'weight' => nil }, 'match_index' => 0 },
            { 'page' => { 'title' => 'Mango', 'weight' => nil }, 'match_index' => 0 }
          ]
        }
      })
    end

    it 'sorts by match_index first, then title alphabetically' do
      generator.sort_sections!
      titles = generator.instance_variable_get(:@sections)['Section A']['pages'].map { |p| p['title'] }
      expect(titles).to eq(%w[Apple Mango Zebra])
    end

    context 'with a Jekyll page object having data' do
      let(:page_a) { instance_double(Jekyll::Page, data: { 'title' => 'A Guide', 'weight' => nil }) }
      let(:page_b) { instance_double(Jekyll::Page, data: { 'title' => 'B Guide', 'weight' => nil }) }

      before do
        generator.instance_variable_set(:@sections, {
          'Guides' => {
            'pages' => [
              { 'page' => page_b, 'match_index' => 0 },
              { 'page' => page_a, 'match_index' => 0 }
            ]
          }
        })
      end

      it 'sorts by title from page.data' do
        generator.sort_sections!
        expect(generator.instance_variable_get(:@sections)['Guides']['pages']).to eq([page_a, page_b])
      end
    end

    context 'with duplicate entries' do
      let(:page) { { 'url' => '/dup/', 'title' => 'Dup' } }

      before do
        generator.instance_variable_set(:@sections, {
          'Section A' => {
            'pages' => [
              { 'page' => page, 'match_index' => 0 },
              { 'page' => page, 'match_index' => 0 }
            ]
          }
        })
      end

      it 'deduplicates pages' do
        generator.sort_sections!
        expect(generator.instance_variable_get(:@sections)['Section A']['pages'].length).to eq(1)
      end
    end
  end

  describe '#fetch_how_tos' do
    let(:how_to_a) do
      instance_double(Jekyll::Document,
                      url: '/how-to/gateway-guide/',
                      data: { 'products' => ['gateway'], 'tags' => ['routing'], 'major_version' => nil })
    end
    let(:how_to_b) do
      instance_double(Jekyll::Document,
                      url: '/how-to/ai-gateway-guide/',
                      data: { 'products' => ['ai-gateway'], 'tags' => ['llm'], 'major_version' => nil })
    end
    let(:collection) { instance_double(Jekyll::Collection, docs: [how_to_a, how_to_b]) }
    let(:site) { instance_double(Jekyll::Site, collections: { 'how-tos' => collection }) }

    before { generator.instance_variable_set(:@current_index, current_index) }

    context 'when index has no major_version' do
      let(:current_index) { {} }

      it 'returns docs matching the given products filter' do
        expect(generator.fetch_how_tos(site, { 'products' => ['gateway'] })).to contain_exactly(how_to_a)
      end

      it 'returns an empty array when no docs match' do
        expect(generator.fetch_how_tos(site, { 'products' => ['mesh'] })).to be_empty
      end

      it 'excludes docs that have major_version set' do
        v1_how_to = instance_double(Jekyll::Document,
                                    data: { 'products' => ['gateway'], 'major_version' => { 'gateway' => 1 } })
        allow(collection).to receive(:docs).and_return([how_to_a, v1_how_to])
        expect(generator.fetch_how_tos(site, { 'products' => ['gateway'] })).to contain_exactly(how_to_a)
      end
    end

    context 'when index has major_version' do
      let(:current_index) { { 'major_version' => { 'ai-gateway' => '1.0' } } }
      let(:v1_how_to) do
        instance_double(Jekyll::Document,
                        url: '/how-to/v1-guide/',
                        data: { 'products' => ['ai-gateway'], 'major_version' => { 'ai-gateway' => 1 } })
      end
      let(:v2_how_to) do
        instance_double(Jekyll::Document,
                        url: '/how-to/v2-guide/',
                        data: { 'products' => ['ai-gateway'], 'major_version' => { 'ai-gateway' => 2 } })
      end

      before { allow(collection).to receive(:docs).and_return([v1_how_to, v2_how_to, how_to_b]) }

      it 'includes only docs whose major_version matches the index' do
        expect(generator.fetch_how_tos(site, { 'products' => ['ai-gateway'] })).to contain_exactly(v1_how_to)
      end

      it 'excludes docs with no major_version even if they match the product criteria' do
        expect(generator.fetch_how_tos(site, { 'products' => ['ai-gateway'] })).not_to include(how_to_b)
      end
    end
  end

  describe '#add_how_to_search' do
    let(:sections) { { 'Guides' => { 'pages' => [] } } }

    before { generator.instance_variable_set(:@sections, sections) }

    let(:match) { { 'title' => 'LLM Guides', 'description' => 'Find LLM guides', 'products' => ['ai-gateway'] } }

    it 'adds an entry with the correct search url' do
      generator.add_how_to_search(nil, 'Guides', match, 0, false, {})
      page = sections['Guides']['pages'].first['page']
      expect(page['url']).to eq('/how-to?products=ai-gateway')
    end

    it 'adds an entry with title and description from match' do
      generator.add_how_to_search(nil, 'Guides', match, 0, false, {})
      page = sections['Guides']['pages'].first['page']
      expect(page['title']).to eq('LLM Guides')
      expect(page['description']).to eq('Find LLM guides')
    end
  end

  describe '#base_page_data (private)' do
    let(:site) { instance_double(Jekyll::Site, source: '/repo') }
    let(:file) { '/repo/_indices/ai-gateway/v1.yaml' }

    context 'when canonical_url, major_version and products are present' do
      let(:index) do
        { 'title' => 'V1 Docs', 'description' => 'desc',
          'canonical_url' => '/index/ai-gateway/', 'major_version' => { 'ai-gateway' => '1.0' },
          'products' => ['ai-gateway'] }
      end

      subject(:data) { generator.send(:base_page_data, file, index, site) }

      it { expect(data['canonical_url']).to eq('/index/ai-gateway/') }
      it { expect(data['major_version']).to eq({ 'ai-gateway' => '1.0' }) }
      it { expect(data['products']).to eq(['ai-gateway']) }
      it { expect(data['slug']).to eq('ai-gateway/v1') }
    end

    context 'when canonical_url, major_version and products are absent' do
      let(:index) { { 'title' => 'Docs', 'description' => 'desc' } }

      subject(:data) { generator.send(:base_page_data, file, index, site) }

      it { expect(data).not_to have_key('canonical_url') }
      it { expect(data).not_to have_key('major_version') }
      it { expect(data).not_to have_key('products') }
    end
  end

  describe '#set_cross_major_banner_info (private)' do
    let(:aigw_product_data) { { 'name' => 'AI Gateway', 'previous_major_url_segment' => 'v<major>' } }
    let(:site) { instance_double(Jekyll::Site, data: { 'products' => { 'ai-gateway' => aigw_product_data } }) }

    context 'when the page has major_version set' do
      let(:page_data) { { 'major_version' => { 'ai-gateway' => '1.0' } } }
      let(:page) { instance_double(Jekyll::Page, data: page_data) }

      before { generator.send(:set_cross_major_banner_info, site, page) }

      it 'sets cross_major_banner_info with the product name' do
        expect(page_data['cross_major_banner_info']['product']).to eq('AI Gateway')
      end

      it 'sets cross_major_banner_info with the MajorVersionResolver label' do
        expect(page_data['cross_major_banner_info']['major_version']).to eq('v1')
      end
    end

    context 'when the page has no major_version' do
      let(:page) { instance_double(Jekyll::Page, data: {}) }

      it 'does not set cross_major_banner_info' do
        generator.send(:set_cross_major_banner_info, site, page)
        expect(page.data).not_to have_key('cross_major_banner_info')
      end
    end
  end

  describe '#match_criteria (private)' do
    let(:data) { { 'products' => ['gateway', 'ai-gateway'], 'tags' => ['security', 'routing'] } }

    it 'returns true when criteria intersects with data' do
      expect(generator.send(:match_criteria, data, { 'products' => ['gateway'] })).to be(true)
    end

    it 'returns false when criteria has no overlap' do
      expect(generator.send(:match_criteria, data, { 'products' => ['mesh'] })).to be(false)
    end

    it 'returns true when all criteria keys intersect' do
      expect(generator.send(:match_criteria, data, { 'products' => ['gateway'], 'tags' => ['security'] })).to be(true)
    end

    it 'returns false when any one key has no overlap' do
      expect(generator.send(:match_criteria, data, { 'products' => ['gateway'], 'tags' => ['performance'] })).to be(false)
    end

    it 'returns true when match has no recognized criteria keys' do
      expect(generator.send(:match_criteria, data, { 'title' => 'something' })).to be(true)
    end

    it 'returns false when data is missing the required key entirely' do
      expect(generator.send(:match_criteria, {}, { 'products' => ['gateway'] })).to be(false)
    end
  end

  describe '#plugin_page? (private)' do
    it { expect(generator.send(:plugin_page?, instance_double(Jekyll::Page, url: '/plugins/ai-proxy/'))).to be(true) }
    it { expect(generator.send(:plugin_page?, instance_double(Jekyll::Page, url: '/ai-gateway/page/'))).to be(false) }
    it { expect(generator.send(:plugin_page?, instance_double(Jekyll::Page, url: '/plugins/'))).to be(true) }
  end

  describe '#page_matches_major_version? (private)' do
    let(:index_major_version) { { 'ai-gateway' => '1.0' } }

    context 'when page major_version matches' do
      let(:page) { instance_double(Jekyll::Page, data: { 'major_version' => { 'ai-gateway' => 1 } }) }

      it { expect(generator.send(:page_matches_major_version?, page, index_major_version)).to be(true) }
    end

    context 'when page major_version does not match' do
      let(:page) { instance_double(Jekyll::Page, data: { 'major_version' => { 'ai-gateway' => 2 } }) }

      it { expect(generator.send(:page_matches_major_version?, page, index_major_version)).to be(false) }
    end

    context 'when page has no major_version' do
      let(:page) { instance_double(Jekyll::Page, data: {}) }

      it { expect(generator.send(:page_matches_major_version?, page, index_major_version)).to be(false) }
    end

    context 'when index major_version uses an integer string like "1.0"' do
      let(:page) { instance_double(Jekyll::Page, data: { 'major_version' => { 'ai-gateway' => 1 } }) }

      it 'compares by the major integer component' do
        expect(generator.send(:page_matches_major_version?, page, { 'ai-gateway' => '1.5' })).to be(true)
      end
    end
  end

  describe '#page_visible_in_index? (private)' do
    context 'when index has no major_version' do
      let(:index) { {} }

      it 'includes plain pages with no releases and no major_version' do
        page = instance_double(Jekyll::Page, data: { 'releases' => nil, 'major_version' => nil })
        expect(generator.send(:page_visible_in_index?, page, index)).to be(true)
      end

      it 'excludes non-canonical versioned pages' do
        page = instance_double(Jekyll::Page, data: { 'releases' => ['3.0'], 'canonical?' => false, 'major_version' => nil })
        expect(generator.send(:page_visible_in_index?, page, index)).to be(false)
      end

      it 'includes canonical versioned pages that have no major_version' do
        page = instance_double(Jekyll::Page, data: { 'releases' => ['3.0'], 'canonical?' => true, 'major_version' => nil })
        expect(generator.send(:page_visible_in_index?, page, index)).to be(true)
      end

      it 'excludes pages that have major_version set (previous-major pages without releases)' do
        page = instance_double(Jekyll::Page, data: { 'releases' => nil, 'major_version' => { 'ai-gateway' => 1 } })
        expect(generator.send(:page_visible_in_index?, page, index)).to be(false)
      end
    end

    context 'when index has major_version' do
      let(:index) { { 'major_version' => { 'ai-gateway' => '1.0' } } }

      it 'includes pages whose major_version matches' do
        page = instance_double(Jekyll::Page, data: { 'major_version' => { 'ai-gateway' => 1 } })
        expect(generator.send(:page_visible_in_index?, page, index)).to be(true)
      end

      it 'excludes pages whose major_version does not match' do
        page = instance_double(Jekyll::Page, url: '/ai-gateway/v2/page/', data: { 'major_version' => { 'ai-gateway' => 2 } })
        expect(generator.send(:page_visible_in_index?, page, index)).to be(false)
      end

      it 'excludes non-plugin pages with no major_version at all' do
        page = instance_double(Jekyll::Page, url: '/ai-gateway/page/', data: { 'releases' => nil })
        expect(generator.send(:page_visible_in_index?, page, index)).to be(false)
      end

      it 'includes plugin pages even when they have no major_version' do
        page = instance_double(Jekyll::Page, url: '/plugins/ai-proxy/', data: { 'major_version' => nil })
        expect(generator.send(:page_visible_in_index?, page, index)).to be(true)
      end
    end
  end

  describe '#config_to_grouped_pages' do
    let(:collection) { instance_double(Jekyll::Collection, docs: []) }
    let(:site) do
      instance_double(Jekyll::Site,
                      config: {},
                      pages: pages,
                      documents: [],
                      collections: { 'how-tos' => collection })
    end
    let(:pages) { [] }

    it 'returns [] when index has no groups key' do
      expect(generator.config_to_grouped_pages(site, {})).to eq([])
    end

    context 'with a path-matching section and a matching page' do
      let(:page) do
        instance_double(Jekyll::Page,
                        url: '/gateway/',
                        data: { 'published' => true, 'skip_index' => false, 'releases' => nil })
      end
      let(:pages) { [page] }
      let(:index) do
        {
          'groups' => [
            { 'sections' => [{ 'title' => 'Overview', 'items' => [{ 'path' => '/gateway/' }] }] }
          ]
        }
      end

      it 'includes the matched page in the section' do
        result = generator.config_to_grouped_pages(site, index)
        expect(result[0]['sections'][0]['pages']).to include(page)
      end
    end

    context 'when page is published: false' do
      let(:page) do
        instance_double(Jekyll::Page,
                        url: '/gateway/',
                        data: { 'published' => false, 'skip_index' => false, 'releases' => nil })
      end
      let(:pages) { [page] }
      let(:index) do
        {
          'groups' => [
            { 'sections' => [{ 'title' => 'Overview', 'items' => [{ 'path' => '/gateway/' }] }] }
          ]
        }
      end

      it 'excludes the page' do
        result = generator.config_to_grouped_pages(site, index)
        expect(result[0]['sections'][0]['pages']).to be_empty
      end
    end

    context 'when page has skip_index: true' do
      let(:page) do
        instance_double(Jekyll::Page,
                        url: '/gateway/',
                        data: { 'published' => true, 'skip_index' => true, 'releases' => nil })
      end
      let(:pages) { [page] }
      let(:index) do
        {
          'groups' => [
            { 'sections' => [{ 'title' => 'Overview', 'items' => [{ 'path' => '/gateway/' }] }] }
          ]
        }
      end

      it 'excludes the page' do
        result = generator.config_to_grouped_pages(site, index)
        expect(result[0]['sections'][0]['pages']).to be_empty
      end
    end

    context 'when index has no major_version and page is versioned (non-canonical)' do
      let(:page) do
        instance_double(Jekyll::Page,
                        url: '/gateway/v3/page/',
                        data: { 'published' => true, 'skip_index' => false,
                                'releases' => ['3.0'], 'canonical?' => false, 'major_version' => nil })
      end
      let(:pages) { [page] }
      let(:index) do
        {
          'groups' => [
            { 'sections' => [{ 'title' => 'Overview', 'items' => [{ 'path' => '/gateway/v3/page/' }] }] }
          ]
        }
      end

      it 'excludes non-canonical versioned pages' do
        result = generator.config_to_grouped_pages(site, index)
        expect(result[0]['sections'][0]['pages']).to be_empty
      end
    end

    context 'when index has no major_version and page has major_version set' do
      let(:page) do
        instance_double(Jekyll::Page,
                        url: '/ai-gateway/v1/how-to/',
                        data: { 'published' => true, 'skip_index' => false,
                                'releases' => nil, 'major_version' => { 'ai-gateway' => 1 } })
      end
      let(:pages) { [page] }
      let(:index) do
        {
          'groups' => [
            { 'sections' => [{ 'title' => 'How-tos', 'items' => [{ 'path' => '/ai-gateway/**/*' }] }] }
          ]
        }
      end

      it 'excludes previous-major pages that have no releases array' do
        result = generator.config_to_grouped_pages(site, index)
        expect(result[0]['sections'][0]['pages']).to be_empty
      end
    end

    context 'when index has major_version' do
      let(:matching_page) do
        instance_double(Jekyll::Page,
                        url: '/ai-gateway/v1/page/',
                        data: { 'published' => true, 'skip_index' => false,
                                'major_version' => { 'ai-gateway' => 1 } })
      end
      let(:other_major_page) do
        instance_double(Jekyll::Page,
                        url: '/ai-gateway/v2/page/',
                        data: { 'published' => true, 'skip_index' => false,
                                'major_version' => { 'ai-gateway' => 2 } })
      end
      let(:canonical_page) do
        instance_double(Jekyll::Page,
                        url: '/ai-gateway/page/',
                        data: { 'published' => true, 'skip_index' => false,
                                'releases' => ['2.0'], 'canonical?' => true })
      end
      let(:pages) { [matching_page, other_major_page, canonical_page] }
      let(:index) do
        {
          'major_version' => { 'ai-gateway' => '1.0' },
          'groups' => [
            {
              'sections' => [
                { 'title' => 'V1 Docs', 'items' => [{ 'path' => '/ai-gateway/**/*' }] }
              ]
            }
          ]
        }
      end

      it 'includes only pages matching the index major_version' do
        result = generator.config_to_grouped_pages(site, index)
        section_pages = result[0]['sections'][0]['pages']
        expect(section_pages).to include(matching_page)
      end

      it 'excludes pages with a different major_version' do
        result = generator.config_to_grouped_pages(site, index)
        expect(result[0]['sections'][0]['pages']).not_to include(other_major_page)
      end

      it 'excludes canonical pages that have no major_version set' do
        result = generator.config_to_grouped_pages(site, index)
        expect(result[0]['sections'][0]['pages']).not_to include(canonical_page)
      end
    end

    context 'when index has major_version and a plugin page is path-matched' do
      let(:plugin_page) do
        instance_double(Jekyll::Page,
                        url: '/plugins/ai-proxy/',
                        data: { 'published' => true, 'skip_index' => false, 'major_version' => nil })
      end
      let(:pages) { [plugin_page] }
      let(:index) do
        {
          'major_version' => { 'ai-gateway' => '1.0' },
          'groups' => [
            { 'sections' => [{ 'title' => 'Plugins', 'items' => [{ 'path' => '/plugins/ai-proxy/' }] }] }
          ]
        }
      end

      it 'includes the plugin page despite it having no major_version' do
        result = generator.config_to_grouped_pages(site, index)
        expect(result[0]['sections'][0]['pages']).to include(plugin_page)
      end
    end

    context 'when section has a url entry (static link)' do
      # url items are processed inside `all.each`, so at least one published page
      # must exist in the site to trigger the loop (the url entry itself is deduped
      # after the first iteration via the `seen` hash).
      let(:any_page) do
        instance_double(Jekyll::Page,
                        url: '/any/',
                        data: { 'published' => true, 'skip_index' => false, 'releases' => nil })
      end
      let(:pages) { [any_page] }
      let(:index) do
        {
          'groups' => [
            {
              'sections' => [
                {
                  'title' => 'External',
                  'items' => [{ 'url' => '/external/', 'title' => 'External Link' }]
                }
              ]
            }
          ]
        }
      end

      it 'includes the static url entry in the section' do
        result = generator.config_to_grouped_pages(site, index)
        pages_in_section = result[0]['sections'][0]['pages']
        expect(pages_in_section.map { |p| p.is_a?(Hash) ? p['url'] : p.url }).to include('/external/')
      end
    end
  end

  describe '#major_version_label (private)' do
    let(:aigw_product_data) { { 'previous_major_url_segment' => 'v<major>' } }
    let(:site) { instance_double(Jekyll::Site, data: { 'products' => { 'ai-gateway' => aigw_product_data } }) }

    it 'delegates to MajorVersionResolver with the correct product data and major integer' do
      expect(generator.send(:major_version_label, site, { 'ai-gateway' => '1.0' })).to eq('v1')
    end

    it 'handles an integer version value' do
      expect(generator.send(:major_version_label, site, { 'ai-gateway' => 1 })).to eq('v1')
    end

    it 'uses the first product in the hash' do
      gw_product_data = { 'previous_major_url_segment' => 'v<major>' }
      gw_site = instance_double(Jekyll::Site, data: { 'products' => { 'gateway' => gw_product_data } })
      expect(generator.send(:major_version_label, gw_site, { 'gateway' => '3.0' })).to eq('v3')
    end
  end

  describe '#link_major_version_indices (private)' do
    let(:aigw_product_data) { { 'previous_major_url_segment' => 'v<major>' } }
    let(:products_data) { { 'ai-gateway' => aigw_product_data } }

    let(:canonical_data) { { 'slug' => 'ai-gateway' } }
    let(:canonical_page) { instance_double(Jekyll::Page, url: '/index/ai-gateway/', data: canonical_data) }

    let(:v1_data) do
      { 'canonical_url' => '/index/ai-gateway/', 'major_version' => { 'ai-gateway' => '1.0' } }
    end
    let(:v1_page) { instance_double(Jekyll::Page, url: '/index/ai-gateway/v1/', data: v1_data) }

    let(:site) do
      instance_double(Jekyll::Site, data: { 'indices' => { 'ai-gateway' => canonical_page,
                                                           'ai-gateway/v1' => v1_page },
                                            'products' => products_data })
    end

    before { generator.send(:link_major_version_indices, site) }

    it 'sets previous_major_urls on the canonical index using MajorVersionResolver key' do
      expect(canonical_data['previous_major_urls']).to eq({ 'v1' => ['/index/ai-gateway/v1/'] })
    end

    it 'does not set previous_major_urls on the versioned index itself' do
      expect(v1_data['previous_major_urls']).to be_nil
    end

    context 'when no canonical index page exists for the given canonical_url' do
      let(:site) do
        instance_double(Jekyll::Site, data: { 'indices' => { 'ai-gateway/v1' => v1_page },
                                              'products' => products_data })
      end

      it 'skips without raising' do
        expect { generator.send(:link_major_version_indices, site) }.not_to raise_error
      end
    end

    context 'when an index has no canonical_url' do
      let(:plain_data) { { 'slug' => 'gateway' } }
      let(:plain_page) { instance_double(Jekyll::Page, url: '/index/gateway/', data: plain_data) }
      let(:site) do
        instance_double(Jekyll::Site, data: { 'indices' => { 'gateway' => plain_page },
                                              'products' => products_data })
      end

      it 'skips the page' do
        generator.send(:link_major_version_indices, site)
        expect(plain_data['previous_major_urls']).to be_nil
      end
    end

    context 'with multiple versioned indices pointing to the same canonical' do
      let(:v2_data) do
        { 'canonical_url' => '/index/ai-gateway/', 'major_version' => { 'ai-gateway' => '2.0' } }
      end
      let(:v2_page) { instance_double(Jekyll::Page, url: '/index/ai-gateway/v2/', data: v2_data) }
      let(:site) do
        instance_double(Jekyll::Site, data: { 'indices' => { 'ai-gateway' => canonical_page,
                                                             'ai-gateway/v1' => v1_page,
                                                             'ai-gateway/v2' => v2_page },
                                              'products' => products_data })
      end

      it 'accumulates all versioned index URLs under their respective labels' do
        expect(canonical_data['previous_major_urls']).to eq({
                                                              'v1' => ['/index/ai-gateway/v1/'],
                                                              'v2' => ['/index/ai-gateway/v2/']
                                                            })
      end
    end
  end

  describe '#indices_relative (private)' do
    let(:site) { instance_double(Jekyll::Site, source: '/repo') }

    it 'strips the _indices/ prefix to give a path relative to that directory' do
      expect(generator.send(:indices_relative, site, '/repo/_indices/gateway.yaml')).to eq('gateway.yaml')
    end

    it 'preserves subdirectory structure' do
      expect(generator.send(:indices_relative, site, '/repo/_indices/ai-gateway/v1.yaml')).to eq('ai-gateway/v1.yaml')
    end
  end

  describe '#page_slug (private)' do
    let(:site) { instance_double(Jekyll::Site, source: '/repo') }

    it 'returns the stem for a top-level file' do
      expect(generator.send(:page_slug, site, '/repo/_indices/gateway.yaml')).to eq('gateway')
    end

    it 'returns the full relative path without extension for a subdirectory file' do
      expect(generator.send(:page_slug, site, '/repo/_indices/ai-gateway/v1.yaml')).to eq('ai-gateway/v1')
    end
  end

  describe '#index_dir (private)' do
    let(:site) { instance_double(Jekyll::Site, source: '/repo') }

    it 'returns "index" for a top-level file' do
      expect(generator.send(:index_dir, site, '/repo/_indices/gateway.yaml')).to eq('index')
    end

    it 'returns "index/<subdir>" for a nested file' do
      expect(generator.send(:index_dir, site, '/repo/_indices/ai-gateway/v1.yaml')).to eq('index/ai-gateway')
    end
  end

  describe '#generate' do
    let(:site) do
      instance_double(Jekyll::Site,
                      config: {},
                      source: '/fake/source',
                      pages: [],
                      documents: [],
                      data: {})
    end

    context 'when skip.indices is configured' do
      let(:site) { instance_double(Jekyll::Site, config: { 'skip' => { 'indices' => true } }) }

      it 'returns early without scanning for index files' do
        expect(Dir).not_to receive(:glob)
        generator.generate(site)
      end
    end
  end
end
