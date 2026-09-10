# frozen_string_literal: true

require 'json'
require_relative '../../../../spec_helper'

RSpec.describe Jekyll::Drops::Plugins::Schema do
  let(:plugin_slug) { 'acl' }
  let(:release_number) { '3.9' }
  let(:schema_dir) { File.join(described_class::SCHEMAS_BASE, release_number) }

  let(:protocols) { %w[http https] }
  let(:required_fields) { %w[allow] }
  let(:schema_json) do
    JSON.dump(
      'properties' => {
        'protocols' => { 'items' => { 'enum' => protocols } },
        'config' => { 'required' => required_fields, 'properties' => { 'allow' => { 'type' => 'array' } } }
      }
    )
  end

  let(:release) { instance_double(Jekyll::Drops::Release, number: release_number) }
  let(:plugin) do
    instance_double(Jekyll::PluginPages::Plugin,
                    slug: plugin_slug, third_party?: false, releases: [release])
  end

  subject(:schema) { described_class.new(release:, plugin:) }

  context 'with mocked FILE_INDEX' do
    before do
      stub_const('Jekyll::Drops::Plugins::Schema::FILE_INDEX',
                 { schema_dir => { 'acl.json' => "#{schema_dir}/ACL.json" } })
      allow(File).to receive(:read).with("#{schema_dir}/ACL.json").and_return(schema_json)
    end

    describe '.all' do
      it 'returns one Schema instance per release' do
        result = described_class.all(plugin:)
        expect(result.size).to eq(1)
        expect(result.first).to be_a(described_class)
      end

      it 'assigns the correct release to each instance' do
        expect(described_class.all(plugin:).first.release).to eq(release)
      end
    end

    describe '#as_json' do
      it 'returns the full parsed schema hash' do
        expect(schema.as_json).to eq(JSON.parse(schema_json))
      end
    end

    describe '#compatible_protocols' do
      it { expect(schema.compatible_protocols).to eq(protocols) }
    end

    describe '#required_fields' do
      it { expect(schema.required_fields).to eq(required_fields) }
    end

    describe 'case-insensitive file lookup' do
      context 'when the file on disk uses all-caps (ACL.json) but slug produces Acl' do
        it 'resolves to the correctly-cased path' do
          expect(File).to receive(:read).with("#{schema_dir}/ACL.json").and_return(schema_json)
          schema.as_json
        end
      end
    end

    describe 'missing schema file' do
      before do
        stub_const('Jekyll::Drops::Plugins::Schema::FILE_INDEX',
                   { schema_dir => {} })
      end

      it 'raises ArgumentError mentioning the plugin slug and release' do
        expect { schema.as_json }.to raise_error(ArgumentError, /acl.*3\.9|3\.9.*acl/i)
      end
    end

    describe 'third-party plugin' do
      let(:plugin_folder) { '/plugins/my-plugin' }
      let(:plugin) do
        instance_double(Jekyll::PluginPages::Plugin,
                        slug: 'my-plugin', third_party?: true,
                        folder: plugin_folder, releases: [release])
      end

      context 'when schema.json exists' do
        before do
          allow(File).to receive(:exist?).with("#{plugin_folder}/schema.json").and_return(true)
          allow(File).to receive(:read).with("#{plugin_folder}/schema.json").and_return(schema_json)
        end

        it { expect(schema.as_json).to eq(JSON.parse(schema_json)) }
      end

      context 'when schema.json is missing' do
        before do
          allow(File).to receive(:exist?).with("#{plugin_folder}/schema.json").and_return(false)
        end

        it 'raises ArgumentError mentioning the plugin slug' do
          expect { schema.as_json }.to raise_error(ArgumentError, /my-plugin/)
        end
      end
    end
  end

  describe 'FILE_INDEX lazy loading' do
    let(:test_dir) { File.join(described_class::SCHEMAS_BASE, '__spec__') }

    before do
      allow(Dir).to receive(:glob)
        .with("#{test_dir}/*.json")
        .and_return(["#{test_dir}/ACL.json", "#{test_dir}/BasicAuth.json"])
    end

    after { described_class::FILE_INDEX.delete(test_dir) }

    it 'builds a lowercase-keyed index for the directory on first access' do
      expect(described_class::FILE_INDEX[test_dir]).to eq(
        'acl.json' => "#{test_dir}/ACL.json",
        'basicauth.json' => "#{test_dir}/BasicAuth.json"
      )
    end

    it 'memoizes the index — Dir.glob is called only once for repeated accesses' do
      3.times { described_class::FILE_INDEX[test_dir] }
      expect(Dir).to have_received(:glob).with("#{test_dir}/*.json").once
    end

    it 'keeps separate caches for different version directories' do
      other_dir = File.join(described_class::SCHEMAS_BASE, '__spec_other__')
      allow(Dir).to receive(:glob).with("#{other_dir}/*.json").and_return([])
      described_class::FILE_INDEX[test_dir]
      described_class::FILE_INDEX[other_dir]
      expect(Dir).to have_received(:glob).twice
      described_class::FILE_INDEX.delete(other_dir)
    end
  end
end
