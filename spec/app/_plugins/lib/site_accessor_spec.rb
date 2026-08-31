# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jekyll::SiteAccessor do
  subject(:accessor) { Class.new { include Jekyll::SiteAccessor }.new }

  let(:build_filter) { Jekyll::BuildFilter.new(env: env) }
  let(:env) { {} }

  before { allow(Jekyll::BuildFilter).to receive(:current).and_return(build_filter) }

  describe '#site_redirects' do
    context 'when in development with PAGE_PATHS configured' do
      before { allow(Jekyll).to receive(:env).and_return('development') }

      let(:env) { { 'PAGE_PATHS' => '/plugins/' } }

      it 'returns an empty hash without reading the _redirects page' do
        expect(accessor.site_redirects).to eq({})
      end
    end

    context 'when not filtering by path' do
      let(:redirects_page) { instance_double(Jekyll::Page, url: '/_redirects', content: "/old /new\n") }
      let(:site) { instance_double(Jekyll::Site, pages: [redirects_page]) }

      before { allow(Jekyll).to receive(:sites).and_return([site]) }

      it 'parses the _redirects page content' do
        expect(accessor.site_redirects).to eq('/old' => '/new')
      end
    end
  end
end
