# frozen_string_literal: true

module ToCheckFilter # rubocop:disable Style/Documentation
  def to_check(input)
    file = template_file(input)

    Liquid::Template
      .parse(File.read(file))
      .render(@context.environments.first,
              registers: @context.registers)
  end

  def template_file(condition)
    if condition
      'app/_includes/icon_true.html'
    else
      'app/_includes/icon_false.html'
    end
  end
end

Liquid::Template.register_filter(ToCheckFilter)
