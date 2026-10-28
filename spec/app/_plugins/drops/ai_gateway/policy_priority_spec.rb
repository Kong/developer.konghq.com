# frozen_string_literal: true

RSpec.describe Jekyll::Drops::AIGateway::PolicyPriority do
  before do
    JekyllSite.instance.data['policies'] = {
      'ai-gateway' => {
        'priority' => {
          'exclude' => ['jwt'],
          'overrides' => { 'ai-nvidia-nemo-guardrail' => 786 }
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
    JekyllSite.instance.data['plugins'] = {
      'credentials' => JekyllSite.instance.data['plugins']['credentials'],
      'priorities' => {
        '310' => {
          'ai-semantic-guard' => 925,
          'ai-nvidia-nemo-guardrail' => 700,
          'ai-prompt-guard' => 750,
          'ai-sanitizer' => 750,
          'jwt' => 1000
        }
      }
    }
    allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance])
  end

  after do
    JekyllSite.instance.data.delete('policies')
    JekyllSite.instance.data.delete('ai_gateway_policies')
    JekyllSite.instance.data['plugins'].delete('priorities')
  end

  def policy(name:, overview_url:, published: true)
    Struct.new(:data).new({ 'name' => name, 'overview_url' => overview_url, 'published' => published })
  end

  subject(:rows) { described_class.all }

  describe '.all' do
    it 'returns drop instances, one per listed policy' do
      expect(rows.size).to eq(4)
      expect(rows).to all(be_a(described_class))
    end

    it 'sorts by priority descending, then title ascending' do
      expect(rows.map(&:title)).to eq(
        ['AI Semantic Guard', 'NVIDIA Nemo Guardrail', 'AI Prompt Guard', 'AI Sanitizer']
      )
    end

    it 'excludes policies on the exclude list' do
      expect(rows.map(&:slug)).not_to include('jwt')
    end

    it 'excludes unpublished policies' do
      expect(rows.map(&:slug)).not_to include('ai-draft-policy')
    end

    it 'drops policies with no resolved priority' do
      expect(rows.map(&:slug)).not_to include('ai-zero-guard')
    end

    it 'resolves the override over the release priorities' do
      nemo = rows.find { |r| r.slug == 'ai-nvidia-nemo-guardrail' }
      expect(nemo.priority).to eq(786)
    end

    it 'falls back to the latest gateway release priorities' do
      guard = rows.find { |r| r.slug == 'ai-semantic-guard' }
      expect(guard.priority).to eq(925)
    end
  end

  describe 'row readers' do
    let(:row) { rows.first }

    it 'exposes title, url, slug, and priority' do
      expect(row.title).to eq('AI Semantic Guard')
      expect(row.url).to eq('/ai-gateway/semantic-guard/')
      expect(row.slug).to eq('ai-semantic-guard')
      expect(row.priority).to eq(925)
    end

    it 'dispatches [] to public readers for template access' do
      expect(row['title']).to eq('AI Semantic Guard')
      expect(row['url']).to eq('/ai-gateway/semantic-guard/')
      expect(row['slug']).to eq('ai-semantic-guard')
      expect(row['priority']).to eq(925)
    end
  end
end
