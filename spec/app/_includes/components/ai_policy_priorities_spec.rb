# frozen_string_literal: true

RSpec.describe 'components/ai_policy_priorities' do
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

  let(:template) do
    <<~LIQUID
      {% ai_policy_priorities %}
    LIQUID
  end

  describe 'markdown output' do
    subject(:rendered) { render_liquid(template, page: { 'output_format' => 'markdown' }) }

    it 'renders the table header' do
      expect(rendered).to include('| AI Policy | Priority |')
    end

    it 'renders one row per listed policy in priority order' do
      rows = rendered.lines.grep(/\[.*\]/)
      expect(rows.size).to eq(4)
      expect(rows[0]).to include('[AI Semantic Guard](/ai-gateway/semantic-guard/) (`ai-semantic-guard`) | 925 |')
      expect(rows[1]).to include(
        '[NVIDIA Nemo Guardrail](/ai-gateway/nemo-guardrail/) (`ai-nvidia-nemo-guardrail`) | 786 |'
      )
      expect(rows[2]).to include('[AI Prompt Guard](/ai-gateway/prompt-guard/) (`ai-prompt-guard`) | 750 |')
      expect(rows[3]).to include('[AI Sanitizer](/ai-gateway/sanitizer/) (`ai-sanitizer`) | 750 |')
    end

    it 'omits excluded, unpublished, and nil-priority policies' do
      expect(rendered).not_to include('JWT')
      expect(rendered).not_to include('AI Draft Policy')
      expect(rendered).not_to include('AI Zero Guard')
    end
  end

  describe 'html output' do
    subject(:html) { Capybara::Node::Simple.new(render_liquid(template)) }

    it 'renders the priorities table' do
      expect(html).to have_css('table.table__sticky')
      expect(html).to have_css('thead th', text: 'AI Policy')
    end

    it 'renders one row per listed policy in priority order' do
      rows = html.all('tbody tr')
      expect(rows.size).to eq(4)
      expect(rows[0]).to have_css("a[href='/ai-gateway/semantic-guard/']", text: 'AI Semantic Guard')
      expect(rows[0]).to have_css('td:first-child code', text: 'ai-semantic-guard')
      expect(rows[0]).to have_css('td:last-child code', text: '925')
      expect(rows[1]).to have_css("a[href='/ai-gateway/nemo-guardrail/']", text: 'NVIDIA Nemo Guardrail')
      expect(rows[1]).to have_css('td:first-child code', text: 'ai-nvidia-nemo-guardrail')
      expect(rows[1]).to have_css('td:last-child code', text: '786')
      expect(rows[2]).to have_css("a[href='/ai-gateway/prompt-guard/']", text: 'AI Prompt Guard')
      expect(rows[2]).to have_css('td:first-child code', text: 'ai-prompt-guard')
      expect(rows[2]).to have_css('td:last-child code', text: '750')
      expect(rows[3]).to have_css("a[href='/ai-gateway/sanitizer/']", text: 'AI Sanitizer')
      expect(rows[3]).to have_css('td:first-child code', text: 'ai-sanitizer')
      expect(rows[3]).to have_css('td:last-child code', text: '750')
    end

    it 'omits excluded, unpublished, and nil-priority policies' do
      expect(html).not_to have_css('tbody a', text: 'JWT')
      expect(html).not_to have_css('tbody a', text: 'AI Draft Policy')
      expect(html).not_to have_css('tbody a', text: 'AI Zero Guard')
    end
  end
end
