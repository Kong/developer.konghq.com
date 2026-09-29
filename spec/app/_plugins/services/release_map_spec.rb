# frozen_string_literal: true

RSpec.describe ReleaseMap do
  let(:fixture_source) { File.expand_path('spec/fixtures/source', Dir.pwd) }
  let(:site) { instance_double(Jekyll::Site, source: fixture_source) }

  describe '.load_all' do
    subject(:result) { described_class.load_all(site) }

    it 'returns entries keyed by source-file path' do
      expect(result).to include(
        'app/_how-tos/ai-gateway/v1/valid-page.md' => { 'canonical_url' => '/ai-gateway/valid-page/' }
      )
    end

    it 'returns pending entries with status and nil canonical_url' do
      expect(result).to include(
        'app/_how-tos/ai-gateway/v1/pending-page.md' => { 'status' => 'pending', 'canonical_url' => nil }
      )
    end

    it 'returns all entries from the YAML files' do
      expect(result.keys).to match_array([
                                           'app/_how-tos/ai-gateway/v1/valid-page.md',
                                           'app/_how-tos/ai-gateway/v1/self-canonical.md',
                                           'app/_how-tos/ai-gateway/v1/pending-page.md',
                                           'app/_how-tos/ai-gateway/v1/blank-url-page.md',
                                           'app/_how-tos/ai-gateway/v1/bad-url-page.md'
                                         ])
    end

    context 'when the releases directory does not exist' do
      let(:site) { instance_double(Jekyll::Site, source: '/nonexistent/source') }

      it 'returns an empty hash' do
        expect(result).to eq({})
      end
    end
  end
end
