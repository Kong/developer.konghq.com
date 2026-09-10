# frozen_string_literal: true

RSpec.describe 'how-tos/validations/grpc-check/snippet.md' do
  let(:template) do
    '{% include how-tos/validations/grpc-check/snippet.md url=config.url method=config.method ' \
      'payload=config.payload response=config.response authority=config.authority port=config.port ' \
      'plaintext=config.plaintext %}'
  end

  subject(:rendered) { render_liquid(template, locals: { 'config' => config }) }
  let(:code) { bash_code_block(rendered) }

  shared_examples 'a valid grpcurl command' do
    it 'renders syntactically valid bash' do
      validate_bash_syntax!(code)
    end
  end

  context 'plaintext, with authority, port 80' do
    let(:config) do
      {
        'url' => '$PROXY_IP',
        'method' => 'hello.HelloService.SayHello',
        'authority' => 'example.com',
        'port' => 80,
        'plaintext' => true,
        'payload' => '{"greeting": "Kong"}',
        'response' => "{\n  \"reply\": \"hello Kong\"\n}"
      }
    end

    include_examples 'a valid grpcurl command'

    it 'renders -plaintext with no -insecure flag' do
      expect(rendered).to eq(<<~'MD'.chomp)
        Use `grpcurl` to send a gRPC request through the proxy:

        ```bash
        grpcurl -d '{"greeting": "Kong"}' -plaintext -authority example.com $PROXY_IP:80 hello.HelloService.SayHello
        ```

        You should see the following response:

        ```json
        {
          "reply": "hello Kong"
        }
        ```
      MD
    end
  end

  context 'no plaintext, with authority, port 443' do
    let(:config) do
      {
        'url' => '$PROXY_IP',
        'method' => 'hello.HelloService.SayHello',
        'authority' => 'example.com',
        'port' => 443,
        'payload' => '{"greeting": "Kong"}',
        'response' => "{\n  \"reply\": \"hello Kong\"\n}"
      }
    end

    include_examples 'a valid grpcurl command'

    it 'renders -insecure with no -plaintext flag' do
      expect(rendered).to eq(<<~'MD'.chomp)
        Use `grpcurl` to send a gRPC request through the proxy:

        ```bash
        grpcurl -d '{"greeting": "Kong"}' -authority example.com -insecure $PROXY_IP:443 hello.HelloService.SayHello
        ```

        You should see the following response:

        ```json
        {
          "reply": "hello Kong"
        }
        ```
      MD
    end
  end

  context 'no authority (synthetic)' do
    let(:config) do
      {
        'url' => '$PROXY_IP',
        'method' => 'hello.HelloService.SayHello',
        'port' => 443,
        'payload' => '{"greeting": "Kong"}',
        'response' => '{}'
      }
    end

    include_examples 'a valid grpcurl command'

    it 'omits the -authority flag' do
      expect(rendered).to eq(<<~'MD'.chomp)
        Use `grpcurl` to send a gRPC request through the proxy:

        ```bash
        grpcurl -d '{"greeting": "Kong"}' -insecure $PROXY_IP:443 hello.HelloService.SayHello
        ```

        You should see the following response:

        ```json
        {}
        ```
      MD
    end
  end
end
