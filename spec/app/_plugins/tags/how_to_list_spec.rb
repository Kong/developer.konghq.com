# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jekyll::RenderHowToList do
  subject(:rendered) { render_liquid(template, page: {}, locals: locals) }

  let(:template) { '{% how_to_list include.config %}' }
  let(:locals) { { 'include' => { 'config' => { 'tags' => ['nonexistent-tag-xyz-zzz'] } } } }

  before { allow(Jekyll::BuildFilter).to receive(:current).and_return(Jekyll::BuildFilter.new(env: env)) }

  context 'when build filtering is active' do
    before { allow(Jekyll).to receive(:env).and_return('development') }

    let(:env) { { 'KONG_PRODUCTS' => 'ai-gateway' } }

    it 'does not raise even though no how-tos match' do
      expect { rendered }.not_to raise_error
    end
  end

  context 'when build filtering is not active' do
    let(:env) { {} }

    it 'raises since no how-tos match' do
      expect { rendered }.to raise_error(/No how-tos found/)
    end
  end
end
