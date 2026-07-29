# frozen_string_literal: true

require_relative '../../../../../spec_helper'
require_relative '../../../../../../app/_plugins/drops/entity_example/presenters/kongctl'

RSpec.describe Jekyll::Drops::EntityExample::Presenters::Kongctl::Base do
  let(:example_drop) { double('example_drop') }
  let(:formats) do
    {
      'kongctl' => {
        'ai_gateway_variables' => {
          'ai_gateway' => { 'placeholder' => 'ai-gateway-name' }
        },
        'event_gateway_variables' => {
          'event_gateway' => { 'placeholder' => 'event-gateway-name' }
        }
      }
    }
  end

  subject(:presenter) { described_class.new(example_drop:) }

  before { allow(presenter).to receive(:formats).and_return(formats) }

  describe '#data' do
    before do
      allow(example_drop).to receive(:data).and_return({ 'name' => 'my-server', 'key' => '$API_SECRET' })
    end

    it 'returns the raw data without env var substitution' do
      expect(presenter.data['key']).to eq('$API_SECRET')
    end

    it 'leaves non-env-var values unchanged' do
      expect(presenter.data['name']).to eq('my-server')
    end
  end

  describe '#config' do
    before do
      allow(example_drop).to receive(:product).and_return('ai-gateway')
      allow(example_drop).to receive(:entity_type).and_return('mcp_server')
    end

    context 'when data contains an env var' do
      before do
        allow(example_drop).to receive(:data).and_return({
          'name' => 'weather-mcp',
          'config' => {
            'query' => { 'key' => ['$WEATHERAPI_API_KEY'] }
          }
        })
      end

      it 'renders the env var as !env VAR_NAME' do
        expect(presenter.config).to include('!env WEATHERAPI_API_KEY')
      end

      it 'does not include the raw $VAR_NAME string' do
        expect(presenter.config).not_to include('$WEATHERAPI_API_KEY')
      end

      it 'does not include the sentinel string' do
        expect(presenter.config).not_to include('__kongctl_env_')
      end
    end

    context 'when data contains no env vars' do
      before do
        allow(example_drop).to receive(:data).and_return({
          'name' => 'my-mcp',
          'config' => { 'url' => 'https://example.com' }
        })
      end

      it 'renders plain values unchanged' do
        expect(presenter.config).to include('url: https://example.com')
      end
    end

    context 'when data contains a lowercase $var (not an env var)' do
      before do
        allow(example_drop).to receive(:data).and_return({
          'name' => 'my-mcp',
          'token' => '$not_an_env_var'
        })
      end

      it 'leaves lowercase $var as-is' do
        expect(presenter.config).to include('$not_an_env_var')
      end
    end
  end
end

RSpec.describe Jekyll::Drops::EntityExample::Presenters::Kongctl::EventGatewayPolicy do
  let(:example_drop) { double('example_drop') }
  let(:target) { double('target', key: 'ingress') }
  let(:formats) do
    {
      'kongctl' => {
        'event_gateway_variables' => {
          'event_gateway' => { 'placeholder' => 'event-gateway-name' },
          'virtual_cluster' => { 'placeholder' => 'virtual-cluster-name' },
          'listener' => { 'placeholder' => 'listener-name' }
        }
      }
    }
  end

  subject(:presenter) { described_class.new(example_drop:) }

  before { allow(presenter).to receive(:formats).and_return(formats) }

  describe '#config' do
    before do
      allow(example_drop).to receive(:product).and_return('event-gateway')
      allow(example_drop).to receive(:entity_type).and_return('policy')
      allow(example_drop).to receive(:policy_target).and_return('virtual_cluster')
      allow(example_drop).to receive(:target).and_return(target)
      allow(example_drop).to receive(:data).and_return({
        'name' => 'my-policy',
        'type' => 'auth',
        'secret' => '$POLICY_SECRET'
      })
    end

    it 'renders env vars as !env VAR_NAME in the virtual_cluster path' do
      expect(presenter.config).to include('!env POLICY_SECRET')
    end

    it 'does not include the sentinel' do
      expect(presenter.config).not_to include('__kongctl_env_')
    end
  end
end
