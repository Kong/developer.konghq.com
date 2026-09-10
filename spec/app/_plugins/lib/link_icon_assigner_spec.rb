# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jekyll::LinkIconAssigner do
  subject(:assigner) { described_class.new(resource, build_filter: build_filter) }

  let(:build_filter) { Jekyll::BuildFilter.new(env: env) }
  let(:env) { {} }
  let(:resource) { { 'url' => '/gateway/foo/' } }

  describe '#process' do
    context 'when build filtering is active' do
      before { allow(Jekyll).to receive(:env).and_return('development') }

      let(:env) { { 'KONG_PRODUCTS' => 'ai-gateway' } }

      it 'assigns the generic icon without resolving the target page' do
        expect(assigner).not_to receive(:site)
        assigner.process
        expect(resource['icon']).to eq('/assets/icons/service-document.svg')
      end
    end

    context 'when build filtering is not active' do
      before { allow(assigner).to receive_messages(site: site, site_redirects: {}) }

      let(:target_page) { instance_double(Jekyll::Page, url: '/gateway/foo/', data: { 'content_type' => 'plugin' }) }
      let(:site) { instance_double(Jekyll::Site, pages: [target_page], documents: []) }

      it 'resolves the icon from the target page content_type' do
        assigner.process
        expect(resource['icon']).to eq('/assets/icons/plug.svg')
      end
    end
  end
end
