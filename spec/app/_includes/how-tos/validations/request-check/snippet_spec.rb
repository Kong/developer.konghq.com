# frozen_string_literal: true

# Config fixtures below are adapted from real {% validation request-check %} blocks in
# app/_how-tos/ai-gateway/*.md, to make sure the curl commands we generate for real docs
# are syntactically valid bash.
RSpec.describe 'how-tos/validations/request-check/snippet.md' do
  let(:template) do
    <<~LIQUID
      {% include how-tos/validations/request-check/snippet.md url=config.url method=config.method headers=config.headers body=config.body body_file=config.body_file form_url_encoded_data=config.form_url_encoded_data display_headers=config.display_headers message=config.message capture=config.capture %}
    LIQUID
  end

  subject(:rendered) { render_liquid(template, locals: { 'config' => config }) }

  let(:code) { bash_code_block(rendered) }

  shared_examples 'a valid curl command' do
    it 'renders syntactically valid bash' do
      validate_bash_syntax!(code)
    end
  end

  context 'minimal url only (get-started-with-ai-agent.md)' do
    let(:config) { { 'url' => '/a2a/.well-known/agent-card.json' } }

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl "/a2a/.well-known/agent-card.json" \
             --no-progress-meter --fail-with-body 
      BASH
    end
  end

  context 'headers and a JSON body (get-started-with-ai-gateway.md)' do
    let(:config) do
      {
        'url' => '/v1/chat/completions',
        'method' => 'POST',
        'headers' => ['Accept: application/json', 'Content-Type: application/json', 'Authorization: Bearer $OPENAI_API_KEY'],
        'body' => { 'messages' => [{ 'role' => 'user', 'content' => 'Say this is a test!' }], 'model' => 'my-gpt-4o' }
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -X POST "/v1/chat/completions" \
             --no-progress-meter --fail-with-body  \
             -H "Accept: application/json"\
             -H "Content-Type: application/json"\
             -H "Authorization: Bearer $OPENAI_API_KEY" \
             --json '{
               "messages": [
                 {
                   "role": "user",
                   "content": "Say this is a test!"
                 }
               ],
               "model": "my-gpt-4o"
             }'
      BASH
    end
  end

  context 'a header only, with display_headers (rate-limit-a2a-traffic.md)' do
    let(:config) do
      {
        'url' => '/a2a/.well-known/agent-card.json',
        'method' => 'GET',
        'display_headers' => true,
        'headers' => ['apikey: a2a-secret-key-1']
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -i -X GET "/a2a/.well-known/agent-card.json" \
             --no-progress-meter --fail-with-body  \
             -H "apikey: a2a-secret-key-1"
      BASH
    end
  end

  context 'a body_file reference (limit-a2a-body-size.md)' do
    let(:config) do
      {
        'url' => '/a2a',
        'method' => 'POST',
        'headers' => ['Content-Type: application/json'],
        'body_file' => '@large_payload.json'
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -X POST "/a2a" \
             --no-progress-meter --fail-with-body  \
             -H "Content-Type: application/json" \
             -F file="@large_payload.json"
      BASH
    end
  end

  context 'form_url_encoded_data with a jq capture (enforce-tiered-ai-budgets-with-kong-identity.md)' do
    let(:config) do
      {
        'url' => '/oauth/token',
        'method' => 'POST',
        'headers' => ['Content-Type: application/x-www-form-urlencoded'],
        'form_url_encoded_data' => {
          'grant_type' => 'client_credentials',
          'client_id' => '$CAROL_CLIENT_ID',
          'client_secret' => '$CAROL_CLIENT_SECRET',
          'scope' => 'budgets-access'
        },
        'capture' => [{ 'variable' => 'CAROL_ACCESS_TOKEN', 'jq' => '.access_token' }]
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        CAROL_ACCESS_TOKEN=$(curl -X POST "/oauth/token" \
             --no-progress-meter --fail-with-body  \
             -H "Content-Type: application/x-www-form-urlencoded" \
             -d "grant_type=client_credentials" \
             -d "client_id=$CAROL_CLIENT_ID" \
             -d "client_secret=$CAROL_CLIENT_SECRET" \
             -d "scope=budgets-access"  | jq -r ".access_token"
        )
      BASH
    end
  end

  context 'a nested JSON body with a command capture (get-started-with-mcp-server.md)' do
    let(:config) do
      {
        'url' => '/weather/',
        'method' => 'POST',
        'headers' => ['Content-Type: application/json', 'Accept: application/json, text/event-stream'],
        'display_headers' => true,
        'body' => {
          'jsonrpc' => '2.0',
          'id' => 1,
          'method' => 'initialize',
          'params' => {
            'protocolVersion' => '2025-06-18',
            'capabilities' => {},
            'clientInfo' => { 'name' => 'weather-mcp-test', 'version' => '1.0.0' }
          }
        },
        'capture' => [{ 'variable' => 'SESSION_ID', 'command' => "grep -i '^mcp-session-id:' | tr -d '\\r' | cut -d' ' -f2" }]
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        SESSION_ID=$(curl -i -X POST "/weather/" \
             --no-progress-meter --fail-with-body  \
             -H "Content-Type: application/json"\
             -H "Accept: application/json, text/event-stream" \
             --json '{
               "jsonrpc": "2.0",
               "id": 1,
               "method": "initialize",
               "params": {
                 "protocolVersion": "2025-06-18",
                 "capabilities": {},
                 "clientInfo": {
                   "name": "weather-mcp-test",
                   "version": "1.0.0"
                 }
               }
             }' | grep -i '^mcp-session-id:' | tr -d '\r' | cut -d' ' -f2
        )
      BASH
    end
  end

  context 'a deeply nested JSON body with an array (get-started-with-ai-agent.md)' do
    let(:config) do
      {
        'url' => '/a2a/',
        'method' => 'POST',
        'headers' => ['Content-Type: application/json'],
        'body' => {
          'jsonrpc' => '2.0',
          'id' => '1',
          'method' => 'message/send',
          'params' => {
            'message' => {
              'kind' => 'message',
              'messageId' => 'msg-001',
              'role' => 'user',
              'parts' => [{ 'kind' => 'text', 'text' => 'What flights are available on route KA-123?' }]
            }
          }
        }
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -X POST "/a2a/" \
             --no-progress-meter --fail-with-body  \
             -H "Content-Type: application/json" \
             --json '{
               "jsonrpc": "2.0",
               "id": "1",
               "method": "message/send",
               "params": {
                 "message": {
                   "kind": "message",
                   "messageId": "msg-001",
                   "role": "user",
                   "parts": [
                     {
                       "kind": "text",
                       "text": "What flights are available on route KA-123?"
                     }
                   ]
                 }
               }
             }'
      BASH
    end
  end

  context 'an expected message (use-ai-prompt-guard-policy.md)' do
    let(:config) do
      {
        'url' => '/chat/completions',
        'method' => 'POST',
        'headers' => ['Content-Type: application/json'],
        'message' => 'prompt pattern is blocked.'
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -X POST "/chat/completions" \
             --no-progress-meter --fail-with-body  \
             -H "Content-Type: application/json"
      BASH
    end

    it 'renders the expected response text outside the curl command' do
      expect(rendered).to include('You should see the following response:')
      expect(rendered).to include('prompt pattern is blocked.')
    end
  end
end
