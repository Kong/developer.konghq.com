# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jekyll::Data::Breadcrumbs do
  subject(:breadcrumbs) { described_class.new(site: site, page: page, build_filter: build_filter) }

  let(:build_filter) { Jekyll::BuildFilter.new(env: env) }
  let(:env) { {} }

  let(:page) { instance_double(Jekyll::Page, data: page_data, relative_path: 'test.md') }
  let(:page_data) { { 'breadcrumbs' => ['/gateway/'] } }

  let(:target_page) { instance_double(Jekyll::Page, url: '/gateway/', data: { 'title' => 'Gateway' }) }
  let(:site) { instance_double(Jekyll::Site, pages: [target_page], documents: []) }

  describe '#process' do
    context 'when the page has no breadcrumbs configured' do
      let(:page_data) { {} }

      it 'does not add a breadcrumbs key' do
        breadcrumbs.process
        expect(page_data).not_to have_key('breadcrumbs')
      end
    end

    context 'when build filtering is active' do
      before { allow(Jekyll).to receive(:env).and_return('development') }

      let(:env) { { 'PAGE_PATHS' => '/gateway/' } }
      let(:site) { instance_double(Jekyll::Site, pages: [], documents: []) }

      it 'leaves the raw breadcrumbs entries untouched, without requiring a matching page to exist' do
        breadcrumbs.process
        expect(page_data['breadcrumbs']).to eq(['/gateway/'])
      end
    end

    context 'when build filtering is not active' do
      it 'resolves breadcrumbs against the site' do
        breadcrumbs.process
        expect(page_data['breadcrumbs']).to eq([{ 'url' => '/gateway/', 'title' => 'Gateway' }])
      end

      context 'when no matching page exists' do
        let(:site) { instance_double(Jekyll::Site, pages: [], documents: []) }

        it 'raises an ArgumentError' do
          expect { breadcrumbs.process }.to raise_error(ArgumentError, /is invalid/)
        end
      end
    end
  end
end
