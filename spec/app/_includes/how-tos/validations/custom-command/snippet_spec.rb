# frozen_string_literal: true

# Config fixtures below are adapted from real {% validation custom-command %} blocks in
# app/_how-tos/**/*.md. Real docs only ever set `expected.return_code` (0 or non-zero) and
# `render_output: false`; none use `expected.stdout` or `expected.stderr`, and none omit
# `return_code` entirely, so those cases are synthetic, built directly from the snippet.md
# logic, to get full branch coverage.
RSpec.describe 'how-tos/validations/custom-command/snippet.md' do
  let(:validations_config) do
    [{ 'id' => 'custom-command', 'expected' => { 'return_code' => 0 } }]
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'validations' => validations_config } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:config) { Jekyll::Drops::Validations::CustomCommand.new(id: 'custom-command', yaml: yaml) }
  let(:template) { '{% include how-tos/validations/custom-command/snippet.md config=config %}' }

  subject(:rendered) { render_liquid(template, locals: { 'config' => config }) }
  let(:code) { bash_code_block(rendered) }

  shared_examples 'a valid bash command' do
    it 'renders syntactically valid bash for the command' do
      validate_bash_syntax!(code)
    end
  end

  context 'return_code 0, no render_output, no stdout/stderr ' \
          '(encrypt-sensitive-data-in-kong-gateway-with-keyring.md)' do
    let(:yaml) do
      {
        'command' => "openssl genrsa -out private.pem 2048\nopenssl rsa -in private.pem -pubout -out public.pem",
        'expected' => { 'return_code' => 0 }
      }
    end

    include_examples 'a valid bash command'

    it 'renders the command then the success-worded return code check' do
      expect(rendered).to eq(<<~'MD')
        ```bash
        openssl genrsa -out private.pem 2048
        openssl rsa -in private.pem -pubout -out public.pem
        ```


        Check the return code of the command to make sure it completed successfully:
        ```bash
        if [[ $? -ne 0 ]]; then
          echo "Did not receive the expected return code"
        fi
        ```

      MD
    end
  end

  context 'render_output: false (monitor-ai-agent-with-opentelemetry.md)' do
    let(:yaml) do
      {
        'command' => 'docker logs otel-collector 2>&1 | grep -A 15 kong.a2a',
        'expected' => { 'return_code' => 0 },
        'render_output' => false
      }
    end

    include_examples 'a valid bash command'

    it 'renders only the command, with no return code check' do
      expect(rendered).to eq(<<~'MD'.chomp)
        ```bash
        docker logs otel-collector 2>&1 | grep -A 15 kong.a2a
        ```
      MD
    end
  end

  context 'return_code 1, no render_output (get-started-with-event-gateway.md)' do
    let(:yaml) do
      {
        'command' => 'kafkactl -C kafkactl.yaml --context vc produce blocked-topic --value="test message"',
        'expected' => { 'message' => 'Failed to produce message', 'return_code' => 1 }
      }
    end

    include_examples 'a valid bash command'

    it 'renders the return code check without the success wording' do
      expect(rendered).to eq(<<~'MD')
        ```bash
        kafkactl -C kafkactl.yaml --context vc produce blocked-topic --value="test message"
        ```


        Check the return code of the command:
        ```bash
        if [[ $? -ne 1 ]]; then
          echo "Did not receive the expected return code"
        fi
        ```

      MD
    end
  end

  context 'expected.stdout only (synthetic)' do
    let(:yaml) { { 'command' => 'kong version', 'expected' => { 'stdout' => '3.9.0', 'return_code' => 0 } } }

    include_examples 'a valid bash command'

    it 'renders the stdout block before the return code check' do
      expect(rendered).to eq(<<~'MD')
        ```bash
        kong version
        ```You should see the following content on `stdout`:

        ```bash
        3.9.0
        ```



        Check the return code of the command to make sure it completed successfully:
        ```bash
        if [[ $? -ne 0 ]]; then
          echo "Did not receive the expected return code"
        fi
        ```

      MD
    end
  end

  context 'expected.stdout and expected.stderr (synthetic)' do
    let(:yaml) do
      {
        'command' => 'kong version --verbose',
        'expected' => { 'stdout' => '3.9.0', 'stderr' => 'warning: deprecated flag', 'return_code' => 0 }
      }
    end

    include_examples 'a valid bash command'

    it 'renders stdout, then "also" worded stderr, then the return code check' do
      expect(rendered).to eq(<<~'MD')
        ```bash
        kong version --verbose
        ```You should see the following content on `stdout`:

        ```bash
        3.9.0
        ```

        You should also see the following content on `stderr`:

        ```bash
        warning: deprecated flag
        ```


        Check the return code of the command to make sure it completed successfully:
        ```bash
        if [[ $? -ne 0 ]]; then
          echo "Did not receive the expected return code"
        fi
        ```

      MD
    end
  end

  context 'expected has no return_code at all (synthetic)' do
    let(:yaml) { { 'command' => 'kong version', 'expected' => { 'stdout' => '3.9.0' } } }

    include_examples 'a valid bash command'

    it 'renders the "check the return code" line with no code block after it' do
      expect(rendered).to eq(<<~'MD')
        ```bash
        kong version
        ```You should see the following content on `stdout`:

        ```bash
        3.9.0
        ```



        Check the return code of the command:
      MD
    end
  end
end
