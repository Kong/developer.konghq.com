# frozen_string_literal: true

RSpec.describe Jekyll::RenderAIPolicyPriorities do
  let(:template) { <<~LIQUID }
    {% ai_policy_priorities %}
  LIQUID

  before do
    allow(Jekyll::Drops::AIGateway::PolicyPriority).to receive(:all).and_return([])
    allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance])
  end

  it 'builds rows through the PolicyPriority drop' do
    render_liquid(template)
    expect(Jekyll::Drops::AIGateway::PolicyPriority).to have_received(:all)
  end

  describe 'template dispatch per output_format' do
    it 'renders the html component for html pages' do
      rendered = render_liquid(template, page: { 'output_format' => 'html' })
      expect(rendered).to include('table__sticky')
    end

    it 'renders the markdown component for markdown pages' do
      rendered = render_liquid(template, page: { 'output_format' => 'markdown' })
      expect(rendered).to include('| AI Policy | Priority |')
      expect(rendered).not_to include('table__sticky')
    end
  end
end
