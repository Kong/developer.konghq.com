# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::Data::MinVersion do
  let(:site) { JekyllSite.instance }
  let(:page) { FakePage.new(data) }

  subject { described_class.new(site:, page:) }

  # MinVersion mutates page.data and, for unreleased pages, the page URL.
  class FakePage
    attr_reader :data
    attr_accessor :url

    def initialize(data)
      @data = data
      @url  = '/ai-gateway/some-page/'
    end
  end

  describe '#process' do
    context 'when the page has a min_version' do
      let(:data) do
        {
          'content_type' => 'how_to',
          'products' => ['ai-gateway'],
          'min_version' => { 'ai-gateway' => '2.0' },
          'major_version' => { 'ai-gateway' => 2 }
        }
      end

      it 'sets latest_release to the newest release in the major' do
        subject.process

        expect(page.data['latest_release'].number).to eq('2.1')
      end
    end

    context 'when the page has no min_version' do
      let(:data) do
        {
          'content_type' => 'how_to',
          'products' => ['ai-gateway'],
          'major_version' => { 'ai-gateway' => 1 }
        }
      end

      it 'still sets latest_release from the major' do
        subject.process

        expect(page.data['latest_release'].number).to eq('1.1')
      end

      it 'does not version the page URL' do
        expect { subject.process }.not_to change(page, :url)
      end
    end

    context 'when the content type is not how_to or landing_page' do
      let(:data) do
        {
          'content_type' => 'reference',
          'products' => ['ai-gateway'],
          'major_version' => { 'ai-gateway' => 1 }
        }
      end

      it 'sets nothing' do
        subject.process

        expect(page.data).not_to have_key('latest_release')
      end
    end
  end
end
