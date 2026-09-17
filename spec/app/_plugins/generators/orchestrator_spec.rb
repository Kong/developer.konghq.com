# frozen_string_literal: true

RSpec.describe Jekyll::GeneratorOrchestrator do
  subject(:orchestrator) { described_class.new }

  let(:order) { described_class::ORDER }

  def index_of(klass)
    order.index(klass) or raise "#{klass} is not in ORDER"
  end

  describe 'ORDER' do
    [
      [Jekyll::PluginsGenerator, Jekyll::AIGatewayPoliciesGenerator],
      [Jekyll::MeshPoliciesGenerator, Jekyll::ReleaseMapLoader],
      [Jekyll::AIGatewayPoliciesGenerator, Jekyll::ReleaseMapLoader],
      [Jekyll::LandingPagesGenerator, Jekyll::ReleaseMapLoader],
      [Jekyll::PageDataGenerator, Jekyll::SitemapGenerator],
      [Jekyll::MarkdownPagesGenerator, Jekyll::RefirectsGenerator]
    ].each do |earlier, later|
      it "runs #{earlier} before #{later}" do
        expect(index_of(earlier)).to be < index_of(later)
      end
    end

    it 'lists every OrderedGenerator subclass exactly once' do
      subclasses = ObjectSpace.each_object(Class).select { |klass| klass < Jekyll::OrderedGenerator && klass.name }

      expect(order).to match_array(subclasses)
    end

    it 'names a real generator for every skip key' do
      expect(order).to include(*described_class::SKIP_KEYS.keys)
    end
  end

  describe '#generate' do
    subject(:generate) { orchestrator.generate(site) }

    let(:site) { instance_double(Jekyll::Site, config: { 'skip' => { 'indices' => true } }) }
    let(:ran) { [] }

    before do
      orchestrator.generators.each do |generator|
        allow(generator).to receive(:generate) { ran << generator.class }
      end
    end

    it 'runs the generators in ORDER' do
      generate

      expect(ran).to eq(order - [Jekyll::IndexGenerator])
    end

    it 'skips a generator whose skip key is set in site.config' do
      generate

      expect(ran).not_to include(Jekyll::IndexGenerator)
    end
  end
end
