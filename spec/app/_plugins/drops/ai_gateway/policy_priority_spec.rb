# frozen_string_literal: true

RSpec.describe Jekyll::Drops::AIGateway::PolicyPriority do
  before do
    JekyllSite.instance.data['policies'] = {
      'ai-gateway' => {
        'priorities' => {
          'ai-semantic-guard' => 925,
          'ai-nvidia-nemo-guardrail' => 786,
          'ai-prompt-guard' => 750,
          'ai-sanitizer' => 750,
          'jwt' => 1000
        }
      }
    }
    JekyllSite.instance.data['ai_gateway_policies'] = {
      'ai-semantic-guard' => policy(name: 'AI Semantic Guard', overview_url: '/ai-gateway/semantic-guard/'),
      'ai-nvidia-nemo-guardrail' => policy(name: 'NVIDIA Nemo Guardrail',
                                           overview_url: '/ai-gateway/nemo-guardrail/'),
      'ai-prompt-guard' => policy(name: 'AI Prompt Guard', overview_url: '/ai-gateway/prompt-guard/'),
      'ai-sanitizer' => policy(name: 'AI Sanitizer', overview_url: '/ai-gateway/sanitizer/'),
      'jwt' => policy(name: 'JWT', overview_url: '/jwt/'),
      'ai-draft-policy' => policy(name: 'AI Draft Policy', overview_url: '/ai-gateway/draft/', published: false),
      'ai-zero-guard' => policy(name: 'AI Zero Guard', overview_url: '/ai-gateway/zero-guard/')
    }
    allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance])
  end

  after do
    JekyllSite.instance.data.delete('policies')
    JekyllSite.instance.data.delete('ai_gateway_policies')
  end

  def policy(name:, overview_url:, published: true)
    Struct.new(:data).new({ 'name' => name, 'overview_url' => overview_url, 'published' => published })
  end

  subject(:rows) { described_class.all }

  describe '.all' do
    it 'returns drop instances, one per listed policy' do
      expect(rows.size).to eq(5)
      expect(rows).to all(be_a(described_class))
    end

    it 'sorts by priority descending, then title ascending' do
      expect(rows.map(&:title)).to eq(
        ['JWT', 'AI Semantic Guard', 'NVIDIA Nemo Guardrail', 'AI Prompt Guard', 'AI Sanitizer']
      )
    end

    it 'excludes unpublished policies' do
      expect(rows.map(&:slug)).not_to include('ai-draft-policy')
    end

    it 'drops policies with no resolved priority' do
      expect(rows.map(&:slug)).not_to include('ai-zero-guard')
    end

    it 'resolves priorities from the ai-gateway priorities json' do
      nemo = rows.find { |r| r.slug == 'ai-nvidia-nemo-guardrail' }
      expect(nemo.priority).to eq(786)

      guard = rows.find { |r| r.slug == 'ai-semantic-guard' }
      expect(guard.priority).to eq(925)
    end
  end

  describe 'row readers' do
    let(:row) { rows.first }

    it 'exposes title, url, slug, and priority' do
      expect(row.title).to eq('JWT')
      expect(row.url).to eq('/jwt/')
      expect(row.slug).to eq('jwt')
      expect(row.priority).to eq(1000)
    end

    it 'dispatches [] to public readers for template access' do
      expect(row['title']).to eq('JWT')
      expect(row['url']).to eq('/jwt/')
      expect(row['slug']).to eq('jwt')
      expect(row['priority']).to eq(1000)
    end
  end
end
