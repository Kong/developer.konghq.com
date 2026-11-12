# frozen_string_literal: true

RSpec.describe Jekyll::HttpRoute do
  let(:page) { { 'path' => 'test.md', 'content' => '' } }

  let(:template) do
    <<~LIQUID
      {% httproute %}
      name: echo
      matches:
      - path: /echo
        service: echo
        port: 1024
      skip_host: true
      {% endhttproute %}
    LIQUID
  end

  subject(:rendered) { render_liquid(template, page: page) }

  let(:html) { Capybara::Node::Simple.new(rendered) }

  describe 'a block with no section' do
    it 'renders the Gateway API command with data-test-step' do
      expect(html).to have_css('div.custom-code-block[data-test-step="block"]')
    end

    it 'does not render another test attribute' do
      expect(html).to have_no_css('[data-test-prereq]')
      expect(html).to have_no_css('[data-test-cleanup]')
    end
  end

  describe 'a block with section: prereqs' do
    let(:template) do
      <<~LIQUID
        {% httproute %}
        name: echo
        matches:
        - path: /echo
          service: echo
          port: 1024
        skip_host: true
        section: prereqs
        {% endhttproute %}
      LIQUID
    end

    it 'renders the Gateway API command with data-test-prereq and no data-test-step' do
      expect(html).to have_css('div.custom-code-block[data-test-prereq="block"]')
      expect(html).to have_no_css('div.custom-code-block[data-test-step]')
    end

    it 'does not render a data-test-cleanup attribute' do
      expect(html).to have_no_css('[data-test-cleanup]')
    end

    it 'keeps no section key in the emitted HTTPRoute manifest' do
      expect(html).to have_no_content('section')
    end
  end

  describe 'a block with section: cleanup' do
    let(:template) do
      <<~LIQUID
        {% httproute %}
        name: echo
        matches:
        - path: /echo
          service: echo
          port: 1024
        skip_host: true
        section: cleanup
        {% endhttproute %}
      LIQUID
    end

    it 'renders the Gateway API command with data-test-cleanup and no data-test-step' do
      expect(html).to have_css('div.custom-code-block[data-test-cleanup="block"]')
      expect(html).to have_no_css('div.custom-code-block[data-test-step]')
      expect(html).to have_no_css('div.custom-code-block[data-test-prereq]')
    end

    it 'keeps no section key in the emitted HTTPRoute manifest' do
      expect(html).to have_no_content('section')
    end
  end

  describe 'a block with an unrecognized section' do
    let(:template) do
      <<~LIQUID
        {% httproute %}
        name: echo
        matches:
        - path: /echo
          service: echo
          port: 1024
        section: prereq
        {% endhttproute %}
      LIQUID
    end

    it 'raises an ArgumentError naming the rejected value' do
      expect { rendered }
        .to raise_error(ArgumentError, /unrecognized section: "prereq"/)
    end
  end
end
