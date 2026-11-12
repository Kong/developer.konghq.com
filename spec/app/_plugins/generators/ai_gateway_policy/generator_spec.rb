# frozen_string_literal: true

RSpec.describe Jekyll::AIGatewayPolicyPages::Generator do
  def example_fixture(name)
    File.join(PROJECT_ROOT, 'spec/fixtures/app/_ai_gateway_policies/ai-sanitizer/examples', name)
  end

  let(:folder) { '/app/_ai_gateway_policies/my-policy' }
  let(:slug) { 'my-policy' }
  let(:scopes_data) { [{ 'name' => slug, 'scopes' => %w[models global] }] }

  let(:site) do
    instance_double(
      Jekyll::Site,
      source: '/app',
      pages: [],
      data: {
        'kong_plugins' => {},
        'policies' => { 'ai-gateway' => { 'scopes' => scopes_data, 'priorities' => { slug => 925 } } },
        'ai_gateway_policies' => {}
      },
      config: { 'ai_gateway_policies' => { 'metadata' => { 'keep' => %w[title name description icon] } } }
    )
  end

  let(:release_info) do
    instance_double(
      Jekyll::ReleaseInfo::Product,
      releases: [],
      latest_available_release: nil,
      latest_release_in_range: nil,
      unreleased?: false,
      min_release: nil
    )
  end

  let(:example_files) do
    [example_fixture('sanitize-pii.yml'), example_fixture('enabled-false.yml')]
  end

  before do
    stub_const('Jekyll::Drops::Plugins::AIGWPolicySchema::FILE_INDEX',
               { 'mypolicy.json' => '/fake/MyPolicy.json' })
    allow(Jekyll).to receive(:sites).and_return([site])
    allow(Jekyll::ReleaseInfo::Product).to receive(:new).and_return(release_info)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(File.join(folder, 'index.md')).and_return(index_md)
    allow(File).to receive(:read).with('/fake/MyPolicy.json').and_return(JSON.dump({ 'properties' => {} }))
    allow(Dir).to receive(:glob).with(File.join(folder, 'examples', '*')).and_return(example_files)
  end

  let(:policy) { Jekyll::AIGatewayPolicyPages::Policy.new(folder:, slug:) }

  subject(:generator) { described_class.new(site, build_filter: Jekyll::BuildFilter.new(env: {})) }

  describe '#generate_pages' do
    subject(:generate_pages) { generator.generate_pages(policy) }

    context 'when the policy has an overview and example files' do
      let(:index_md) { "---\nproducts:\n  - ai-gateway\n---\nOverview body.\n" }

      it 'adds one example page per example file to site.pages' do
        generate_pages

        example_page_urls = site.pages.map(&:url).select { |url| url.include?('/examples/') }
        expect(example_page_urls).to contain_exactly(
          '/ai-gateway/policies/my-policy/examples/enabled-false/',
          '/ai-gateway/policies/my-policy/examples/sanitize-pii/'
        )
      end

      it 'adds the overview and reference pages alongside the example pages' do
        generate_pages

        expect(site.pages.map(&:url)).to include(
          '/ai-gateway/policies/my-policy/',
          '/ai-gateway/policies/my-policy/reference/'
        )
      end

      it 'registers the overview page under the generator key' do
        generate_pages

        expect(site.data['ai_gateway_policies'][slug].url).to eq('/ai-gateway/policies/my-policy/')
      end
    end

    context 'when the policy has no overview but has example files' do
      let(:index_md) { "---\nproducts:\n  - ai-gateway\n---\n" }

      it 'adds no example pages' do
        generate_pages

        expect(site.pages.map(&:url)).not_to include(a_string_including('/examples/'))
      end

      it 'still adds the reference page' do
        generate_pages

        expect(site.pages.map(&:url)).to include('/ai-gateway/policies/my-policy/reference/')
      end
    end
  end
end
