# frozen_string_literal: true

RSpec.describe Jekyll::Drops::EventGatewayQuickstart do
  it 'is not a member of the validations drop family' do
    expect(described_class.ancestors).not_to include(Jekyll::Drops::Validations::Base)
  end

  it 'is not constructed through the validations factory' do
    expect { Jekyll::Drops::Validations::Base.make_for(id: 'quickstart', yaml: {}) }
      .to raise_error(ArgumentError, 'Missing Drop for `quickstart`')
  end
end

RSpec.describe Jekyll::EventGatewayQuickstart do
  let(:page) { { 'output_format' => 'html', 'path' => 'test.md' } }

  subject(:rendered) { render_liquid(template, page: page) }

  let(:html) { Capybara::Node::Simple.new(rendered) }

  describe 'the command' do
    context 'with no env map' do
      let(:template) do
        <<~LIQUID
          {% event_gateway_quickstart %}
          {% endevent_gateway_quickstart %}
        LIQUID
      end

      it 'renders the command on a single line' do
        expect(rendered).to include(
          'curl -Ls https://get.konghq.com/event-gateway | bash -s -- -k $KONNECT_TOKEN -N kafka_event_gateway'
        )
      end
    end

    context 'with one or more env entries' do
      let(:template) do
        <<~LIQUID
          {% event_gateway_quickstart %}
          env:
            FOO: bar
            BAZ: qux
          {% endevent_gateway_quickstart %}
        LIQUID
      end

      it 'renders with backslash continuations and one flag per entry' do
        expect(rendered).to include(<<~COMMAND.strip)
          curl -Ls https://get.konghq.com/event-gateway | bash -s -- \\
            -k $KONNECT_TOKEN \\
            -N kafka_event_gateway \\
            -e "FOO=bar" \\
            -e "BAZ=qux"
        COMMAND
      end
    end

    context 'with an env value containing a comma, a space, and an equals sign' do
      let(:template) do
        <<~LIQUID
          {% event_gateway_quickstart %}
          env:
            MY_VAR: "a=b, c d"
          {% endevent_gateway_quickstart %}
        LIQUID
      end

      it 'renders the value intact' do
        expect(rendered).to include('-e "MY_VAR=a=b, c d"')
      end
    end
  end

  describe 'the test declaration' do
    context 'by default' do
      let(:template) do
        <<~LIQUID
          {% event_gateway_quickstart %}
          env:
            FOO: bar
          {% endevent_gateway_quickstart %}
        LIQUID
      end

      it 'is present, carrying the step name and every environment entry' do
        div = html.find('div[data-test-step]')
        payload = JSON.parse(div['data-test-step'])

        expect(payload['name']).to eq('quickstart')
        expect(payload['config']['env']).to eq({ 'FOO' => 'bar' })
      end
    end

    context 'section: none' do
      let(:template) do
        <<~LIQUID
          {% event_gateway_quickstart %}
          section: none
          {% endevent_gateway_quickstart %}
        LIQUID
      end

      it 'emits no test declaration' do
        expect(html).not_to have_css('div[data-test-step]')
      end
    end
  end

  describe 'malformed yaml' do
    let(:template) do
      <<~LIQUID
        {% event_gateway_quickstart %}
        env:
          FOO: 'unterminated
        {% endevent_gateway_quickstart %}
      LIQUID
    end

    it 'raises an error naming the page and showing the offending lines' do
      expect { rendered }.to raise_error(
        ArgumentError, /On `test\.md`, the following \{% event_gateway_quickstart %\} block contains a malformed yaml/
      )
    end
  end

  describe 'markdown output_format' do
    let(:page) { { 'output_format' => 'markdown', 'path' => 'test.md' } }
    let(:template) do
      <<~LIQUID
        {% event_gateway_quickstart %}
        {% endevent_gateway_quickstart %}
      LIQUID
    end

    it 'renders the instructions with no HTML wrapper' do
      expect(rendered).not_to include('<div')
    end

    it 'still renders the command' do
      expect(rendered).to include('curl -Ls https://get.konghq.com/event-gateway')
    end
  end
end
