# frozen_string_literal: true

require 'yaml'

module YamlDump # rubocop:disable Style/Documentation
  def yaml_dump(yaml)
    YAML.dump(yaml)
  end
end

Liquid::Template.register_filter(YamlDump)
