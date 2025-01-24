# frozen_string_literal: true

module EscapeEnvVariablesFilter
  def escape_env_variables(input)
    input.gsub(/(\$[A-Z_][A-Z0-9_]*)/, '\'\1\'')
  end
end

Liquid::Template.register_filter(EscapeEnvVariablesFilter)
