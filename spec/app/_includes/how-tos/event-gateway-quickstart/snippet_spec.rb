# frozen_string_literal: true

RSpec.describe 'how-tos/event-gateway-quickstart/snippet.md' do
  let(:config) { Jekyll::Drops::EventGatewayQuickstart.new(yaml: yaml) }
  let(:template) { '{% include how-tos/event-gateway-quickstart/snippet.md config=config %}' }

  subject(:rendered) { render_liquid(template, locals: { 'config' => config }) }
  let(:code) { bash_code_block(rendered) }

  shared_examples 'a valid shell command' do
    it 'renders syntactically valid shell' do
      validate_bash_syntax!(code)
    end
  end

  context 'with no env map' do
    let(:yaml) { {} }

    include_examples 'a valid shell command'

    it 'renders the command on a single line' do
      expect(code).to eq(
        'curl -Ls https://get.konghq.com/event-gateway | bash -s -- -k $KONNECT_TOKEN -N kafka_event_gateway \\'
      )
    end
  end

  context 'with one or more env entries' do
    let(:yaml) { { 'env' => { 'FOO' => 'bar', 'BAZ' => 'qux' } } }

    include_examples 'a valid shell command'

    it 'renders with backslash continuations and one flag per entry' do
      expect(code).to eq(<<~COMMAND.strip)
        curl -Ls https://get.konghq.com/event-gateway | bash -s -- -k $KONNECT_TOKEN -N kafka_event_gateway \\
          -e "FOO=bar" \\
          -e "BAZ=qux"
      COMMAND
    end
  end

  context 'with an env value containing a comma, a space, and an equals sign' do
    let(:yaml) { { 'env' => { 'MY_VAR' => 'a=b, c d' } } }

    include_examples 'a valid shell command'

    it 'renders the value intact' do
      expect(code).to include('-e "MY_VAR=a=b, c d"')
    end
  end
end
