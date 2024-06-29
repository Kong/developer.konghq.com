# frozen_string_literal: true

module Jekyll
  class PluginNameTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @text = text.strip
    end

    # TODO: Read this mapping from a config file
    def render(context)
      t = variable_to_value(context, @text.to_s)

      r = {
        'rate-limiting' => 'Rate Limiting',
        'rate-limiting-advanced' => 'Rate Limiting Advanced',
        'ai-rate-limiting-advanced' => 'AI Rate Limiting Advanced',
      }[t]

      return r if r

      t
    end

    def variable_to_value(context, variable)
      path = variable.split('.')
      # 0 is the page scope, 1 is the local scope
      [0, 1].each do |k|
        next unless context.scopes[k]
            
        ref = context.scopes[k].dig(*path)
        variable = ref if ref
      end

      variable
    end
  end
end

Liquid::Template.register_tag('plugin_name', Jekyll::PluginNameTag)
