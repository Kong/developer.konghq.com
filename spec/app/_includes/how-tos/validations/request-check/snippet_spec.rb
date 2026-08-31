# frozen_string_literal: true

# Config fixtures below are adapted from real {% validation request-check %} blocks in
# app/_how-tos/**/*.md, to make sure the curl commands we generate for real docs
# are syntactically valid bash. A few (mtls, form_data, body_cmd, output, expected_headers)
# have zero real-doc usage anywhere in the repo, so those fixtures are synthetic, built
# directly from the snippet.md logic, to get full branch coverage.
RSpec.describe 'how-tos/validations/request-check/snippet.md' do
  let(:template) do
    <<~LIQUID
      {% include how-tos/validations/request-check/snippet.md url=config.url method=config.method headers=config.headers body=config.body body_file=config.body_file body_cmd=config.body_cmd form_data=config.form_data form_url_encoded_data=config.form_url_encoded_data display_headers=config.display_headers message=config.message capture=config.capture count=config.count user=config.user cookie_jar=config.cookie_jar cookie=config.cookie insecure=config.insecure sleep=config.sleep mtls=config.mtls output=config.output expected_headers=config.expected_headers %}
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

  context 'user and cookie_jar (configure-oidc-with-session-auth.md)' do
    let(:config) do
      {
        'url' => '/anything',
        'method' => 'GET',
        'user' => 'alex:doe',
        'display_headers' => true,
        'cookie_jar' => 'example-user'
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -i -X GET "/anything" \
             --no-progress-meter --fail-with-body  \
             -u alex:doe \
             --cookie-jar example-user
      BASH
    end
  end

  context 'a cookie (configure-oidc-with-session-auth.md)' do
    let(:config) do
      {
        'url' => '/anything',
        'method' => 'GET',
        'display_headers' => true,
        'cookie' => 'example-user'
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -i -X GET "/anything" \
             --no-progress-meter --fail-with-body  \
             --cookie example-user
      BASH
    end
  end

  context 'insecure with a JSON body (enable-oauth2-authentication-with-kong-gateway.md)' do
    let(:config) do
      {
        'url' => 'https://localhost:8443/anything/oauth2/token',
        'method' => 'POST',
        'headers' => ['Content-Type: application/json'],
        'insecure' => true,
        'body' => { 'client_id' => '$CLIENT_ID', 'client_secret' => '$CLIENT_SECRET', 'grant_type' => 'client_credentials' }
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -k -X POST "https://localhost:8443/anything/oauth2/token" \
             --no-progress-meter --fail-with-body  \
             -H "Content-Type: application/json" \
             --json '{
               "client_id": "'$CLIENT_ID'",
               "client_secret": "'$CLIENT_SECRET'",
               "grant_type": "client_credentials"
             }'
      BASH
    end
  end

  context 'a body with an array of scalars (validate-incoming-json-request-bodies.md)' do
    let(:config) do
      {
        'url' => '/anything',
        'method' => 'POST',
        'headers' => ['Content-Type: application/json'],
        'display_headers' => true,
        'body' => { 'name' => 'Jason', 'age' => 20, 'gender' => 'male', 'parents' => ['Joseph', 'Viva'] }
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -i -X POST "/anything" \
             --no-progress-meter --fail-with-body  \
             -H "Content-Type: application/json" \
             --json '{
               "name": "Jason",
               "age": 20,
               "gender": "male",
               "parents": [
                 "Joseph",
                 "Viva"
               ]
             }'
      BASH
    end
  end

  context 'a request loop with no other params (collect-metrics-with-datadog-and-prometheus-plugin.md)' do
    let(:config) { { 'url' => '/anything', 'count' => 10 } }

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        for _  in {1..10}; do
        curl "/anything" \
             --no-progress-meter --fail-with-body  \
        ; done
      BASH
    end
  end

  context 'insecure with a jq capture (configure-oidc-with-kong-oauth2.md)' do
    let(:config) do
      {
        'url' => 'https://localhost:8443/anything/oauth2/token',
        'method' => 'POST',
        'headers' => ['Content-Type: application/json'],
        'insecure' => true,
        'body' => { 'client_id' => 'client', 'client_secret' => 'secret', 'grant_type' => 'client_credentials' },
        'capture' => [{ 'variable' => 'ACCESS_TOKEN', 'jq' => '.access_token' }]
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        ACCESS_TOKEN=$(curl -k -X POST "https://localhost:8443/anything/oauth2/token" \
             --no-progress-meter --fail-with-body  \
             -H "Content-Type: application/json" \
             --json '{
               "client_id": "client",
               "client_secret": "secret",
               "grant_type": "client_credentials"
             }' | jq -r ".access_token"
        )
      BASH
    end
  end

  context 'sleep before the request (kic-service-healthchecks.md)' do
    let(:config) do
      {
        'url' => '$PROXY_IP/httpbin/status/200',
        'display_headers' => true,
        'sleep' => 15
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        sleep 15 && curl -i "$PROXY_IP/httpbin/status/200" \
             --no-progress-meter --fail-with-body 
      BASH
    end
  end

  context 'a second real count-loop case, no continuation (kic-service-healthchecks.md)' do
    let(:config) do
      {
        'url' => '$PROXY_IP/httpbin/status/500',
        'display_headers' => true,
        'count' => 2
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        for _  in {1..2}; do
        curl -i "$PROXY_IP/httpbin/status/500" \
             --no-progress-meter --fail-with-body  \
        ; done
      BASH
    end
  end

  context 'a message with no other params (filter-requests-based-on-header-names.md)' do
    let(:config) do
      {
        'url' => '/anything',
        'display_headers' => true,
        'message' => 'Invalid Credentials'
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -i "/anything" \
             --no-progress-meter --fail-with-body 
      BASH
    end

    it 'renders the expected response text outside the curl command' do
      expect(rendered).to include('You should see the following response:')
      expect(rendered).to include('Invalid Credentials')
    end
  end

  context 'more than one capture, exercising the capture_size > 1 branch (synthetic — no real doc uses 2+ captures)' do
    let(:config) do
      {
        'url' => '/oauth/token',
        'method' => 'POST',
        'headers' => ['Content-Type: application/json'],
        'body' => { 'client_id' => 'client', 'client_secret' => 'secret', 'grant_type' => 'client_credentials' },
        'capture' => [
          { 'variable' => 'ACCESS_TOKEN', 'jq' => '.access_token' },
          { 'variable' => 'EXPIRES_IN', 'jq' => '.expires_in' }
        ]
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command, wrapped in a shared _response variable' do
      expect(code).to eq(<<~'BASH'.chomp)
        _response=$(curl -X POST "/oauth/token" \
             --no-progress-meter --fail-with-body  \
             -H "Content-Type: application/json" \
             --json '{
               "client_id": "client",
               "client_secret": "secret",
               "grant_type": "client_credentials"
             }')
      BASH
    end

    it 'renders a separate export block for each capture' do
      expect(rendered).to include('Export the env variables:')
      expect(rendered).to include('export ACCESS_TOKEN=$(echo "$_response" | jq -r ".access_token")')
      expect(rendered).to include('export EXPIRES_IN=$(echo "$_response" | jq -r ".expires_in")')
    end
  end

  context 'mtls (synthetic — no real doc uses mtls)' do
    let(:config) { { 'url' => 'https://secure.example.com/orders', 'method' => 'GET', 'mtls' => true } }

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -X GET -k --key key.pem --cert cert.pem "https://secure.example.com/orders" \
             --no-progress-meter --fail-with-body 
      BASH
    end
  end

  context 'form_data, a multipart upload (synthetic — no real doc uses form_data)' do
    let(:config) do
      {
        'url' => '/upload',
        'method' => 'POST',
        'form_data' => { 'file' => '@photo.png', 'description' => 'profile picture' }
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -X POST "/upload" \
             --no-progress-meter --fail-with-body  \
             -F file="@photo.png" \
             -F description="profile picture" 
      BASH
    end
  end

  context 'body_cmd, a shell command substitution as the body (synthetic — no real doc uses body_cmd)' do
    let(:config) do
      {
        'url' => '/anything',
        'method' => 'POST',
        'headers' => ['Content-Type: application/json'],
        'body_cmd' => '$(cat payload.json)'
      }
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -X POST "/anything" \
             --no-progress-meter --fail-with-body  \
             -H "Content-Type: application/json" \
             --json "$(cat payload.json)"
      BASH
    end
  end

  context 'output, saving the response to a file (synthetic — no real doc uses output)' do
    let(:config) { { 'url' => '/anything', 'method' => 'GET', 'output' => 'response.json' } }

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -X GET "/anything" \
             -o response.json --no-progress-meter --fail-with-body 
      BASH
    end
  end

  context 'expected_headers, a pluralized list (synthetic — no real doc uses expected_headers)' do
    let(:config) do
      {
        'url' => '/anything',
        'method' => 'GET',
        'display_headers' => true,
        'expected_headers' => ['X-RateLimit-Remaining: 99', 'X-RateLimit-Limit: 100']
      }
    end

    include_examples 'a valid curl command'

    it 'renders the expected headers outside the curl command, pluralized' do
      expect(rendered).to include('You should see the following headers:')
      expect(rendered).to include('X-RateLimit-Remaining: 99')
      expect(rendered).to include('X-RateLimit-Limit: 100')
    end
  end
end
