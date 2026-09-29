# frozen_string_literal: true

RSpec.shared_examples 'a block that rejects malformed yaml' do |tag_name|
  context 'malformed yaml' do
    let(:template) do
      <<~LIQUID
        {% #{tag_name} %}
        url: 'unterminated
        {% end#{tag_name} %}
      LIQUID
    end

    it "raises an error worded for {% #{tag_name} %}" do
      expect { rendered }.to raise_error(ArgumentError, /the following \{% #{tag_name} %\} block contains a malformed yaml/)
    end
  end
end
