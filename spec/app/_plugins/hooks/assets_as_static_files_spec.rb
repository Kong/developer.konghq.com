# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'the :site, :post_read hook that turns assets into static files' do
  subject(:trigger) { Jekyll::Hooks.trigger :site, :post_read, site }

  let(:source) { Dir.mktmpdir }
  let(:site) do
    Jekyll::Site.new(
      Jekyll.configuration(
        'source' => source,
        'destination' => File.join(source, '_site'),
        'permalink' => 'pretty',
        'quiet' => true
      )
    )
  end

  def add_page(relative_path, content)
    full_path = File.join(source, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)

    Jekyll::Page.new(site, source, File.dirname(relative_path), File.basename(relative_path)).tap do |page|
      site.pages << page
    end
  end

  after { FileUtils.remove_entry(source) }

  context 'with a page under assets/' do
    let!(:page) { add_page('assets/mesh/crds/kuma.io_meshidentities.yaml', "---\nfoo: bar\n") }

    it 'removes it from site.pages' do
      trigger
      expect(site.pages).not_to include(page)
    end

    it 'adds a static file with the same relative path' do
      trigger
      expect(site.static_files.map(&:relative_path)).to eq(['/assets/mesh/crds/kuma.io_meshidentities.yaml'])
    end

    it 'adds a static file with the same url' do
      trigger
      expect(site.static_files.first.url).to eq(page.url)
    end
  end

  context 'with a page under .repos/kuma/app/assets/' do
    let!(:page) { add_page('.repos/kuma/app/assets/mesh/index.md', "---\ntitle: Mesh\n---\n") }

    it 'keeps it as a page' do
      trigger
      expect(site.pages).to include(page)
      expect(site.static_files).to be_empty
    end
  end

  context 'with a page outside assets/' do
    let!(:page) { add_page('gateway/index.md', "---\ntitle: Gateway\n---\n") }

    it 'keeps it as a page' do
      trigger
      expect(site.pages).to include(page)
      expect(site.static_files).to be_empty
    end
  end
end
