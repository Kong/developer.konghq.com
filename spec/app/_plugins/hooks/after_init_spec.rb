# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'the :site, :after_init hook' do
  subject(:trigger) { Jekyll::Hooks.trigger :site, :after_init, site }

  let(:source) { Dir.mktmpdir }
  let(:config) { { 'exclude' => [] } }
  let(:site) { instance_double(Jekyll::Site, source: source, config: config) }
  let(:filter) { Jekyll::BuildFilter.new(env: env) }
  let(:env) { {} }

  before do
    %w[gateway ai-gateway _data assets].each { |dir| FileUtils.mkdir_p(File.join(source, dir)) }
    allow(Jekyll::BuildFilter).to receive(:current).and_return(filter)
  end

  after { FileUtils.remove_entry(source) }

  context 'when not in development' do
    before { allow(Jekyll).to receive(:env).and_return('test') }

    let(:env) { { 'PAGE_PATHS' => '/gateway/' } }

    it 'does not exclude any subfolders' do
      trigger
      expect(config['exclude']).to eq([])
    end
  end

  context 'when in development with no PAGE_PATHS configured' do
    before { allow(Jekyll).to receive(:env).and_return('development') }

    it 'does not exclude any subfolders' do
      trigger
      expect(config['exclude']).to eq([])
    end
  end

  context 'when in development with PAGE_PATHS configured' do
    before { allow(Jekyll).to receive(:env).and_return('development') }

    let(:env) { { 'PAGE_PATHS' => '/gateway/' } }

    it 'excludes subfolders whose first url segment is not requested' do
      trigger
      expect(config['exclude']).to eq(['ai-gateway'])
    end

    it 'keeps folders matching the requested url segment' do
      trigger
      expect(config['exclude']).not_to include('gateway')
    end

    it 'keeps folders with a protected prefix regardless of the requested path' do
      trigger
      expect(config['exclude']).not_to include('_data', 'assets')
    end
  end
end
