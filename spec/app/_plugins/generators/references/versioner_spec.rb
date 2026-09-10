# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::ReferencePages::Versioner do
  let(:site) { JekyllSite.build }

  subject { described_class.new(site:, page:) }

  describe '#process' do
    xcontext 'when the page has max_release'

    context 'without a major_version' do
      context 'and having multiple major versions' do
        let(:page) { site.pages.find { |p| p.url == '/ai-gateway/reference-page/' } }

        it 'sets metadata and generate pages' do
          expect(page.data['major_version']).to be_nil

          subject.process

          expect(page.data['base_url']).to eq('/ai-gateway/reference-page/')
          expect(page.data['release'].number).to eq('2.1')
          expect(page.data['releases'].map(&:number)).to eq(['2.1', '2.0'])
          expect(page.data['releases_dropdown']).to be_a(Jekyll::Drops::ReleasesDropdown)
          expect(page.data['releases_dropdown'].options.map(&:url))
            .to match_array(
              ['/ai-gateway/reference-page/', '/ai-gateway/reference-page/2.0/']
            )
          expect(page.data['canonical_url']).to eq('/ai-gateway/reference-page/')
          expect(page.data['canonical?']).to be(true)
        end

        context 'when the page is versioned' do
          let(:page) { site.pages.find { |p| p.url == '/ai-gateway/reference-page/' } }

          before { page.data['versioned'] = true }

          it 'sets metadata and generate pages' do
            expect(page.data['major_version']).to be_nil

            subject.process

            expect(page.data['base_url']).to eq('/ai-gateway/reference-page/')
            expect(page.data['release'].number).to eq('2.1')
            expect(page.data['releases'].map(&:number)).to eq(['2.1', '2.0'])
            expect(page.data['releases_dropdown']).to be_a(Jekyll::Drops::ReleasesDropdown)
            expect(page.data['releases_dropdown'].options.map(&:url))
              .to match_array(['/ai-gateway/reference-page/', '/ai-gateway/reference-page/2.0/'])
            expect(page.data['canonical_url']).to eq('/ai-gateway/reference-page/')
            expect(page.data['canonical?']).to be(true)
          end
        end
      end

      context 'having only one major version' do
        context 'when the page is not versioned' do
          let(:page) { site.pages.find { |p| p.url == '/gateway/reference-page/' } }

          it 'sets metadata and generate pages' do
            expect(page.data['major_version']).to be_nil
            expect(page.data['versioned']).to be_nil

            subject.process

            expect(page.data['base_url']).to eq('/gateway/reference-page/')
            expect(page.data['release'].number).to eq('3.10')
            expect(page.data['releases'].map(&:number)).to eq(['3.10', '3.9'])
            expect(page.data['releases_dropdown']).to be_a(Jekyll::Drops::ReleasesDropdown)
            expect(page.data['releases_dropdown'].options.map(&:url))
              .to match_array(['/gateway/reference-page/', '/gateway/reference-page/3.9/'])
            expect(page.data['canonical_url']).to eq('/gateway/reference-page/')
            expect(page.data['canonical?']).to be(true)
          end
        end

        context 'when the page is versioned' do
          let(:page) { site.pages.find { |p| p.url == '/gateway/install/' } }

          it 'sets metadata and generate pages' do
            expect(page.data['major_version']).to be_nil
            expect(page.data['versioned']).to be(true)

            subject.process

            expect(page.data['base_url']).to eq('/gateway/install/')
            expect(page.data['release'].number).to eq('3.10')
            expect(page.data['releases'].map(&:number)).to eq(['3.10', '3.9'])
            expect(page.data['releases_dropdown']).to be_a(Jekyll::Drops::ReleasesDropdown)
            expect(page.data['releases_dropdown'].options.map(&:url))
              .to match_array(['/gateway/install/', '/gateway/install/3.9/'])
            expect(page.data['canonical_url']).to eq('/gateway/install/')
            expect(page.data['canonical?']).to be(true)
          end
        end
      end
    end

    context 'with a major_version' do
      let(:page) { site.pages.find { |p| p.url == '/ai-gateway/v1/reference-page/' } }

      it 'sets metadata and generate pages - within the major version' do
        expect(page.data['major_version']).to eq({ 'ai-gateway' => 1 })

        subject.process

        expect(page.data['base_url']).to eq('/ai-gateway/v1/reference-page/')
        expect(page.data['release'].number).to eq('1.1')
        expect(page.data['releases'].map(&:number)).to eq(['1.1', '1.0'])
        expect(page.data['releases_dropdown']).to be_a(Jekyll::Drops::ReleasesDropdown)
        expect(page.data['releases_dropdown'].options.map(&:url))
          .to match_array(['/ai-gateway/v1/reference-page/1.0/', '/ai-gateway/v1/reference-page/1.1/'])

        # points to the canonical_url set in the config file for the major version
        expect(page.data['canonical_url']).to eq('/ai-gateway/reference-page/')
        expect(page.data['canonical?']).to be(false)
      end

      context 'when the page is versioned' do
        context 'and having multiple major versions' do
          let(:page) { site.pages.find { |p| p.url == '/ai-gateway/v1/reference-page/' } }

          before { page.data['versioned'] = true }

          it 'sets metadata and generate pages - within the major version' do
            expect(page.data['major_version']).to eq({ 'ai-gateway' => 1 })
            expect(page.data['versioned']).to be(true)

            subject.process

            expect(page.data['base_url']).to eq('/ai-gateway/v1/reference-page/')
            expect(page.data['release'].number).to eq('1.1')
            expect(page.data['releases'].map(&:number)).to eq(['1.1', '1.0'])
            expect(page.data['releases_dropdown']).to be_a(Jekyll::Drops::ReleasesDropdown)
            expect(page.data['releases_dropdown'].options.map(&:url))
              .to match_array(['/ai-gateway/v1/reference-page/1.0/', '/ai-gateway/v1/reference-page/1.1/'])

            # points to the canonical_url set in the config file for the major version
            expect(page.data['canonical_url']).to eq('/ai-gateway/reference-page/')
            expect(page.data['canonical?']).to be(false)
          end
        end

        context 'and having only one major version' do
          let(:page) { site.pages.find { |p| p.url == '/gateway/reference-page/' } }

          before { page.data['versioned'] = true }

          it 'sets metadata and generate pages' do
            expect(page.data['major_version']).to be_nil
            expect(page.data['versioned']).to be(true)

            subject.process

            expect(page.data['base_url']).to eq('/gateway/reference-page/')
            expect(page.data['release'].number).to eq('3.10')
            expect(page.data['releases'].map(&:number)).to eq(['3.10', '3.9'])
            expect(page.data['releases_dropdown']).to be_a(Jekyll::Drops::ReleasesDropdown)
            expect(page.data['releases_dropdown'].options.map(&:url))
              .to match_array(['/gateway/reference-page/', '/gateway/reference-page/3.9/'])

            # points to the canonical_url set in the config file for the major version
            expect(page.data['canonical_url']).to eq('/gateway/reference-page/')
            expect(page.data['canonical?']).to be(true)
          end
        end
      end
    end
  end

  describe '#generate_pages!' do
    xcontext 'when the page is a plugin changelog' do
      it 'returns an empty array' do
        expect(subject.generate_pages!).to eq([])
      end
    end

    context 'without a major_version' do
      context 'and having multiple major versions' do
        let(:page) { site.pages.find { |p| p.url == '/ai-gateway/reference-page/' } }
        it 'does not generate versioned pages' do
          expect(page.data['major_version']).to be_nil
          expect(page.data['versioned']).to be_nil

          expect(subject.generate_pages!).to eq([])
        end
      end

      context 'having only one major version' do
        context 'when the page is versioned' do
          let(:page) { site.pages.find { |p| p.url == '/gateway/install/' } }

          it 'generates one Jekyll page per version - within the major version' do
            expect(page.data['major_version']).to be_nil
            expect(page.data['versioned']).to be(true)
            expect(subject).to receive(:generate_pages!).and_call_original

            pages = subject.process

            expect(pages.size).to eq(2)

            expect(pages[0].url).to eq('/gateway/install/3.10/')
            expect(pages[0].data['seo_noindex']).to be(true)
            expect(pages[0].data['canonical?']).to be(false)
            expect(pages[0].data['canonical_url']).to eq('/gateway/install/')

            expect(pages[1].url).to eq('/gateway/install/3.9/')
            expect(pages[1].data['seo_noindex']).to be(true)
            expect(pages[1].data['canonical?']).to be(false)
            expect(pages[1].data['canonical_url']).to eq('/gateway/install/')
          end
        end

        context 'when the page is not versioned' do
          let(:page) { site.pages.find { |p| p.url == '/gateway/reference-page/' } }
          it 'does not generate versioned pages' do
            expect(page.data['major_version']).to be_nil
            expect(page.data['versioned']).to be_nil
            expect(subject).to receive(:generate_pages!).and_call_original

            expect(subject.process).to eq([])
          end
        end
      end
    end

    context 'with a major_version' do
      let(:page) { site.pages.find { |p| p.url == '/ai-gateway/v1/reference-page/' } }

      context 'when the page is not versioned' do
        it 'does not generate versioned pages' do
          expect(page.data['major_version']).to eq({ 'ai-gateway' => 1 })
          expect(subject).to receive(:generate_pages!).and_call_original

          expect(subject.process).to eq([])
        end
      end

      context 'when the page is versioned' do
        before { page.data['versioned'] = true }
        it 'generate pages - within the major version' do
          expect(page.data['major_version']).to eq({ 'ai-gateway' => 1 })
          expect(page.data['versioned']).to be(true)
          expect(subject).to receive(:generate_pages!).and_call_original

          pages = subject.process
          expect(pages.size).to eq(2)

          expect(pages[0].url).to eq('/ai-gateway/v1/reference-page/1.1/')
          expect(pages[0].data['seo_noindex']).to be(true)
          expect(pages[0].data['canonical?']).to be(false)
          expect(pages[0].data['canonical_url']).to eq('/ai-gateway/reference-page/')

          expect(pages[1].url).to eq('/ai-gateway/v1/reference-page/1.0/')
          expect(pages[1].data['seo_noindex']).to be(true)
          expect(pages[1].data['canonical?']).to be(false)
          expect(pages[1].data['canonical_url']).to eq('/ai-gateway/reference-page/')
        end
      end
    end
  end
end
