# frozen_string_literal: true

# Config fixtures below are adapted from real {% validation rate-limit-check %} blocks in
# app/_how-tos/ai-gateway/rate-limit-a2a-traffic.md,
# app/_how-tos/gateway/multiple-rate-limits-window-sizes.md, and
# app/_how-tos/kubernetes-ingress-controller/kic-get-started-proxy-caching.md and
# kic-plugin-rate-limiting.md. No real doc combines multiple headers, `sleep`, or an
# `output.expected` without `output.explanation`, so those contexts are synthetic, built
# directly from snippet.md's conditionals, to get full branch coverage.
RSpec.describe 'how-tos/validations/rate-limit-check/snippet.md' do
  let(:template) do
    '{% include how-tos/validations/rate-limit-check/snippet.md iterations=config.iterations ' \
      'url=config.url headers=config.headers sleep=config.sleep grep=config.grep output=config.output %}'
  end

  subject(:rendered) { render_liquid(template, locals: { 'config' => config }) }
  let(:code) { bash_code_block(rendered) }

  shared_examples 'a valid bash command' do
    it 'renders syntactically valid bash' do
      validate_bash_syntax!(code)
    end
  end

  context 'minimal, no headers/grep/sleep/output (multiple-rate-limits-window-sizes.md)' do
    let(:config) { { 'iterations' => 11, 'url' => '/anything' } }

    include_examples 'a valid bash command'

    it 'renders the exact loop' do
      expect(rendered).to eq(<<~MD)
        ```bash
        for _ in {1..11}; do
        #{'  curl  -i /anything  '}
          echo
        done
        ```

      MD
    end
  end

  context 'a single header, no grep (rate-limit-a2a-traffic.md)' do
    let(:config) { { 'iterations' => 5, 'url' => '/a2a/.well-known/agent-card.json', 'headers' => ['apikey: a2a-secret-key-1'] } }

    include_examples 'a valid bash command'

    it 'renders the header on its own continuation line' do
      expect(rendered).to eq(<<~MD)
        ```bash
        for _ in {1..5}; do
          curl  -i /a2a/.well-known/agent-card.json \\
        #{'       -H "apikey: a2a-secret-key-1" '}
          echo
        done
        ```

      MD
    end
  end

  context 'grep without headers (kic-plugin-rate-limiting.md)' do
    let(:config) { { 'iterations' => 10, 'url' => '/echo', 'grep' => '(< RateLimit-Remaining)' } }

    include_examples 'a valid bash command'

    it 'switches to -sv and pipes into grep' do
      expect(rendered).to eq(<<~'MD')
        ```bash
        for _ in {1..10}; do
          curl  -sv /echo  2>&1 | grep -E "(< RateLimit-Remaining)"
          echo
        done
        ```

      MD
    end
  end

  context 'a header with grep and a full output block (kic-get-started-proxy-caching.md)' do
    let(:config) do
      {
        'iterations' => 6,
        'url' => '/echo',
        'headers' => ['apikey:example-key'],
        'grep' => '(Status|< HTTP)',
        'output' => {
          'explanation' => 'The first request results in `X-Cache-Status: Miss`.',
          'expected' => [
            { 'value' => ['< HTTP/1.1 200 OK', '< X-Cache-Status: Miss'] },
            { 'value' => ['< HTTP/1.1 429 Too Many Requests'] }
          ]
        }
      }
    end

    include_examples 'a valid bash command'

    it 'renders the header, the grep pipe, and the explanation with expected output' do
      expect(rendered).to eq(<<~'MD')
        ```bash
        for _ in {1..6}; do
          curl  -sv /echo \
               -H "apikey:example-key" 2>&1 | grep -E "(Status|< HTTP)"
          echo
        done
        ```

        <br />
        The first request results in `X-Cache-Status: Miss`.
        <br />


        ```text
        < HTTP/1.1 200 OK
        < X-Cache-Status: Miss

        < HTTP/1.1 429 Too Many Requests
        ```
        {:.no-copy-code}
      MD
    end
  end

  context 'an explanation with no expected output (kic-plugin-rate-limiting.md)' do
    let(:config) do
      {
        'iterations' => 6,
        'url' => '/echo',
        'output' => {
          'explanation' => 'The `RateLimit-Remaining` header indicates how many requests are remaining.'
        }
      }
    end

    include_examples 'a valid bash command'

    it 'renders the explanation with no trailing text block' do
      expect(rendered).to eq(<<~MD)
        ```bash
        for _ in {1..6}; do
        #{'  curl  -i /echo  '}
          echo
        done
        ```

        <br />
        The `RateLimit-Remaining` header indicates how many requests are remaining.
        <br />

      MD
    end
  end

  context 'multiple headers, exercising the forloop.last continuation (synthetic)' do
    let(:config) { { 'iterations' => 3, 'url' => '/anything', 'headers' => ['Accept: application/json', 'apikey: test-key'] } }

    include_examples 'a valid bash command'

    it 'chains the header lines with backslash continuations except the last' do
      expect(rendered).to eq(<<~MD)
        ```bash
        for _ in {1..3}; do
          curl  -i /anything \\
               -H "Accept: application/json"\\
        #{'       -H "apikey: test-key" '}
          echo
        done
        ```

      MD
    end
  end

  context 'a sleep between requests (synthetic)' do
    let(:config) { { 'iterations' => 3, 'url' => '/anything', 'sleep' => 2 } }

    include_examples 'a valid bash command'

    it 'renders a sleep line before the loop ends' do
      expect(rendered).to eq(<<~MD)
        ```bash
        for _ in {1..3}; do
        #{'  curl  -i /anything  '}
          echo
          sleep 2
        done
        ```

      MD
    end
  end

  context 'output.expected with no explanation (synthetic)' do
    let(:config) do
      {
        'iterations' => 2,
        'url' => '/anything',
        'output' => { 'expected' => [{ 'value' => ['< HTTP/1.1 429 Too Many Requests'] }] }
      }
    end

    include_examples 'a valid bash command'

    it 'renders the expected text block with no explanation or <br /> tags' do
      expect(rendered).to eq(<<~MD)
        ```bash
        for _ in {1..2}; do
        #{'  curl  -i /anything  '}
          echo
        done
        ```


        ```text
        < HTTP/1.1 429 Too Many Requests
        ```
        {:.no-copy-code}
      MD
    end
  end
end
