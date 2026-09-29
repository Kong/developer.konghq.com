# frozen_string_literal: true

RSpec.describe 'how-tos/validations/env-variables/snippet.md' do
  let(:template) { '{% include how-tos/validations/env-variables/snippet.md variables=variables %}' }

  subject(:rendered) { render_liquid(template, locals: { 'variables' => variables }) }
  let(:code) { bash_code_block(rendered) }

  shared_examples 'a valid bash command' do
    it 'renders syntactically valid bash' do
      validate_bash_syntax!(code)
    end
  end

  context 'a single variable (synthetic)' do
    let(:variables) { { 'KONNECT_TOKEN' => 'kpat_xxx' } }

    include_examples 'a valid bash command'

    it 'renders one export line' do
      expect(rendered).to eq(<<~'MD'.chomp)
        ```bash
        export KONNECT_TOKEN="kpat_xxx"
        ```
      MD
    end
  end

  context 'multiple variables, in insertion order (synthetic)' do
    let(:variables) { { 'KONNECT_TOKEN' => 'kpat_xxx', 'KONNECT_CONTROL_PLANE_ID' => 'abc-123' } }

    include_examples 'a valid bash command'

    it 'renders one export line per variable, in order' do
      expect(rendered).to eq(<<~'MD'.chomp)
        ```bash
        export KONNECT_TOKEN="kpat_xxx"
        export KONNECT_CONTROL_PLANE_ID="abc-123"
        ```
      MD
    end
  end

  context 'zero variables (synthetic — see report: reachable via validate_yaml! when only ' \
          '`section`/`indent` are set)' do
    let(:variables) { {} }

    it 'renders an empty bash fence with no export lines' do
      expect(rendered).to eq(<<~'MD'.chomp)
        ```bash
        ```
      MD
    end
  end
end
