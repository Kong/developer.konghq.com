# frozen_string_literal: true

RSpec.describe Jekyll::Drops::PolicyConfigExample::AIGateway do
  def example_fixture(name)
    File.join(PROJECT_ROOT, 'spec/fixtures/app/_ai_gateway_policies/ai-sanitizer/examples', name)
  end

  let(:scopes) { %w[ai-model ai-consumer global] }
  let(:example_file) { example_fixture('sanitize-pii.yml') }

  subject(:drop) { ai_gateway_policy_config_example(file: example_file, scopes: scopes) }

  it { expect(drop.product).to eq('ai-gateway') }

  it 'builds the example URL from the policy slug and the example file' do
    expect(drop.url).to eq('/ai-gateway/policies/ai-sanitizer/examples/sanitize-pii/')
  end

  describe '#targets' do
    context 'without a scopes key in the example' do
      it 'defaults to the policy scopes' do
        expect(drop.targets).to eq(%w[ai-model ai-consumer global])
      end
    end

    context 'with a scopes subset in the example' do
      let(:example_file) { example_fixture('scopes-subset.yml') }

      it 'restricts the targets to the subset' do
        expect(drop.targets).to eq(['global'])
      end
    end
  end

  describe '#data' do
    context 'with enabled and condition omitted' do
      let(:example_file) { example_fixture('minimal.yml') }

      it 'defaults enabled to true and omits the condition key' do
        expect(drop.data).to eq(
          'name' => 'pii-sanitizer',
          'display_name' => 'PII Sanitizer',
          'type' => 'ai-sanitizer',
          'enabled' => true,
          'config' => { 'patterns' => ['email'] }
        )
      end
    end

    context 'with enabled false and a condition' do
      let(:example_file) { example_fixture('enabled-false.yml') }

      it 'holds the overridden enabled and the condition' do
        expect(drop.data).to include(
          'enabled' => false,
          'condition' => '{"type":"json","key":"model"}'
        )
      end
    end
  end

  describe 'build errors' do
    context 'with an unsupported scope in the subset' do
      let(:example_file) { example_fixture('invalid-scope.yml') }

      it 'raises naming the file and the supported scopes' do
        expect { drop }
          .to raise_error(
            ArgumentError,
            "Invalid `scopes` in #{example_file}, supported scopes: ai-model, ai-consumer, global"
          )
      end
    end

    context 'with global set in the example' do
      let(:example_file) { example_fixture('sets-global.yml') }

      it 'raises naming the file and stating that the target sets global' do
        expect { drop }
          .to raise_error(
            ArgumentError,
            "Invalid `global` in #{example_file}: the target sets `global`, remove the `global` key"
          )
      end
    end

    context 'with a missing display_name' do
      let(:example_file) { example_fixture('missing-display-name.yml') }

      it 'raises naming the file' do
        expect { drop }
          .to raise_error(ArgumentError, "Missing `display_name` in #{example_file}")
      end
    end

    context 'with a nil display_name' do
      let(:example_file) { example_fixture('nil-display-name.yml') }

      it 'raises naming the file' do
        expect { drop }
          .to raise_error(ArgumentError, "Missing `display_name` in #{example_file}")
      end
    end

    context 'with an unsupported tool' do
      let(:example_file) { example_fixture('unsupported-tool.yml') }

      it 'raises naming the file and the supported tools' do
        expect { drop }
          .to raise_error(
            ArgumentError,
            "Invalid `tools` in #{example_file}, supported tools: kongctl, konnect-api, terraform"
          )
      end
    end
  end
end
