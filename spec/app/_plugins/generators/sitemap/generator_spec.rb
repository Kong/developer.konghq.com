# frozen_string_literal: true

require_relative '../../../../../app/_plugins/generators/sitemap/generator'

RSpec.describe Jekyll::Sitemap::Generator do
  subject { described_class.run(site) }

  let(:site) { instance_double(Jekyll::Site, pages: pages, documents: documents) }
  let(:pages) { [] }
  let(:documents) { [] }

  def build_page(url:, data: {})
    instance_double(Jekyll::Page, url: url, data:).tap do |p|
      allow(p).to receive(:[]) { |k| data[k] }
    end
  end

  def build_document(url:, data: {})
    instance_double(Jekyll::Document, url: url, data:).tap do |p|
      allow(p).to receive(:[]) { |k| data[k] }
    end
  end

  describe '.run' do
    context 'with no pages or documents' do
      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end

    context 'with a canonical page' do
      let(:pages) { [build_page(url: '/foo/', data: { 'canonical?' => true })] }

      it 'emits an entry with weekly changefreq and priority 1.0' do
        expect(subject).to eq([{ 'url' => '/foo/', 'changefreq' => 'weekly', 'priority' => '1.0' }])
      end
    end

    context 'with a canonical document' do
      let(:documents) { [build_document(url: '/bar/', data: { 'canonical?' => true })] }

      it 'emits an entry for the document' do
        expect(subject).to eq([{ 'url' => '/bar/', 'changefreq' => 'weekly', 'priority' => '1.0' }])
      end
    end

    context 'with a non-canonical page' do
      let(:pages) { [build_page(url: '/foo/', data: { 'canonical?' => false })] }

      it 'omits the page' do
        expect(subject).to eq([])
      end
    end

    context 'with a non-canonical document' do
      let(:documents) { [build_document(url: '/bar/', data: { 'canonical?' => false })] }

      it 'omits the document' do
        expect(subject).to eq([])
      end
    end

    context 'with a canonical page whose data has canonical? set to nil' do
      let(:pages) do
        [instance_double(Jekyll::Page, url: '/foo/', data: {}).tap do |p|
          allow(p).to receive(:[]).with('canonical?').and_return(nil)
        end]
      end

      it 'treats nil canonical? as non-canonical and omits it' do
        expect(subject).to eq([])
      end
    end

    context 'with a canonical document flagged skip_sitemap' do
      let(:documents) { [build_document(url: '/bar/', data: { 'canonical?' => true, 'skip_sitemap' => true })] }

      it 'omits the document' do
        expect(subject).to eq([])
      end
    end

    context 'with a canonical page flagged skip_sitemap' do
      let(:pages) { [build_page(url: '/foo/', data: { 'canonical?' => true, 'skip_sitemap' => true })] }

      it 'still includes the page because skip_sitemap only applies to documents' do
        expect(subject).to eq([{ 'url' => '/foo/', 'changefreq' => 'weekly', 'priority' => '1.0' }])
      end
    end

    context 'with a page whose url ends in .md' do
      let(:pages) { [build_page(url: '/foo.md', data: { 'canonical?' => true })] }

      it 'skips the .md page' do
        expect(subject).to eq([])
      end
    end

    context 'with a document whose url ends in .md' do
      let(:documents) { [build_document(url: '/foo.md', data: { 'canonical?' => true })] }

      it 'skips the .md document' do
        expect(subject).to eq([])
      end
    end

    context 'with a page under /.well-known/' do
      let(:pages) { [build_page(url: '/.well-known/security.txt', data: { 'canonical?' => true })] }

      it 'skips the page' do
        expect(subject).to eq([])
      end
    end

    context 'with a document under /.well-known/' do
      let(:documents) { [build_document(url: '/.well-known/something', data: { 'canonical?' => true })] }

      it 'skips the document' do
        expect(subject).to eq([])
      end
    end

    context 'with several pages and documents' do
      let(:pages) do
        [
          build_page(url: '/zebra/', data: { 'canonical?' => true }),
          build_page(url: '/apple/', data: { 'canonical?' => true }),
          build_page(url: '/banana/', data: { 'canonical?' => false }),
          build_page(url: '/skip.md', data: { 'canonical?' => true }),
          build_page(url: '/.well-known/security.txt', data: { 'canonical?' => true })
        ]
      end
      let(:documents) do
        [
          build_document(url: '/mango/', data: { 'canonical?' => true }),
          build_document(url: '/orange/', data: { 'canonical?' => true, 'skip_sitemap' => true }),
          build_document(url: '/cherry/', data: { 'canonical?' => false }),
          build_document(url: '/date/', data: { 'canonical?' => true })
        ]
      end

      it 'returns canonical, non-skipped entries sorted by url' do
        expect(subject.map { |e| e['url'] }).to eq(['/apple/', '/date/', '/mango/', '/zebra/'])
      end

      it 'attaches the standard changefreq and priority to every entry' do
        expect(subject).to all(include('changefreq' => 'weekly', 'priority' => '1.0'))
      end
    end

    context 'with two pages whose urls sort lexicographically' do
      let(:pages) do
        [
          build_page(url: '/b/', data: { 'canonical?' => true }),
          build_page(url: '/a/', data: { 'canonical?' => true }),
          build_page(url: '/c/', data: { 'canonical?' => true })
        ]
      end

      it 'sorts entries by url ascending' do
        expect(subject.map { |e| e['url'] }).to eq(['/a/', '/b/', '/c/'])
      end
    end

    context 'a page from a major version that is not the latest that is flagged as canonical by mistake' do
      let(:pages) do
        [
          build_page(url: '/v1/foo/', data: { 'canonical?' => true, 'major_version' => { 'ai-gateway': 1 } })
        ]
      end

      it 'does not include the page in the sitemap' do
        expect(subject.map { |e| e['url'] }).not_to include('/v1/foo/')
      end
    end
  end
end
