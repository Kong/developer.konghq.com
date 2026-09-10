# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jekyll::PluginPages::Generator do
  subject(:generator) { described_class.new(site, build_filter: build_filter) }

  let(:site) { instance_double(Jekyll::Site) }
  let(:build_filter) { Jekyll::BuildFilter.new(env: env) }
  let(:env) { {} }

  describe '#skip_locally?' do
    context 'when the build filter excludes /plugins/' do
      before { allow(Jekyll).to receive(:env).and_return('development') }

      let(:env) { { 'PAGE_PATHS' => '/gateway/' } }

      it { expect(generator.skip_locally?).to be(true) }
    end

    context 'when the build filter does not exclude /plugins/' do
      it { expect(generator.skip_locally?).to be(false) }
    end
  end
end
