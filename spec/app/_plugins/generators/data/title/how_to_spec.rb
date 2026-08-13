# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::Data::Title::HowTo do
  let(:page) { instance_double(Jekyll::Page, data: { 'title' => 'Configure Rate Limiting' }, url: '/how-tos/configure-rate-limiting/') }
  let(:site) { instance_double(Jekyll::Site) }

  subject { described_class.new(page:, site:) }

  describe '#title_sections' do
    it { expect(subject.title_sections).to eq(['How to: Configure Rate Limiting']) }
  end

  describe '#llm_title' do
    it { expect(subject.llm_title).to eq('Configure Rate Limiting') }
  end
end
