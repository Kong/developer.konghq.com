# frozen_string_literal: true

require_relative '../../../spec_helper'
require_relative '../../../../app/_plugins/generators/site_data'

RSpec.describe Jekyll::SiteDataGenerator do
  subject(:generator) { described_class.new }

  describe '#product_latest_release' do
    let(:site) { instance_double(Jekyll::Site, data: data) }

    let(:data) do
      {
        'products' => {
          'gateway' => {
            'releases' => [
              { 'release' => '3.9', 'latest' => true },
              { 'release' => '3.8' }
            ]
          },
          'ai-gateway' => {
            'releases' => [
              { 'release' => '2.2', 'version' => '2.2.0', 'latest' => true },
              { 'release' => '2.1', 'version' => '2.1.0' }
            ]
          },
          'insomnia' => {}
        }
      }
    end

    it 'sets the latest release for a non-hyphenated product slug' do
      generator.product_latest_release(site)

      expect(site.data['gateway_latest']).to eq({ 'release' => '3.9', 'latest' => true })
      expect(site.data['gateway_releases']).to eq(data['products']['gateway']['releases'])
    end

    it 'sets the latest release for a hyphenated product slug, keyed with underscores' do
      generator.product_latest_release(site)

      expect(site.data['ai_gateway_latest']).to eq({ 'release' => '2.2', 'version' => '2.2.0', 'latest' => true })
      expect(site.data['ai_gateway_releases']).to eq(data['products']['ai-gateway']['releases'])
    end

    it 'does not set latest/releases keys for a product with no releases' do
      generator.product_latest_release(site)

      expect(site.data).not_to have_key('insomnia_latest')
      expect(site.data).not_to have_key('insomnia_releases')
    end
  end
end
