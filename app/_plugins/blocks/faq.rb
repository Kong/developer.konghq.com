# frozen_string_literal: true

module Jekyll
  class RenderFaq < Liquid::Block
    def render(context)
      text = super
      qa = YAML.load(text)
      @c = context.registers[:site].find_converter_instance(
        Jekyll::Converters::Markdown
      )
      generate_faq(qa)
    end

    private
    
    def generate_faq(text)
      text.map { |faq| single_faq(faq) }.join
    end

    def single_faq(text)
      q = @c.convert(text['q']).sub(/<p>/, '').sub(%r{</p>}, '')
      a = @c.convert(text['a'])
      <<~FAQ
        <details class="mb-2">
          <summary class="rounded mb-0.5 bg-gray-200 p-2">#{q}</summary>
          #{a}
        </details>
      FAQ
     end

  end
end

Liquid::Template.register_tag('faq', Jekyll::RenderFaq)
