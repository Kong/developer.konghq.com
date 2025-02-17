# frozen_string_literal: true

Jekyll::Hooks.register :pages, :pre_render do |page|
  # Also allow for a newline after endif_version when in a table
  # strip extra new lines
  page.content = page.content.gsub(/\|\s*\n\n\s*{% if_version /, "|\n{% if_version ")
  page.content = page.content.gsub(/\|\s*\n{% endif_version %}\n+\|/, "|\n{% endif_version -%}\n\|")
  page.content = page.content.gsub(/\|\s*\n{% endif_version %}\n+\s*{% if_version (.*) %}\n/) do |_match|
    "|\n{% endif_version -%}\n{% if_version #{Regexp.last_match(1)} -%}\n"
  end
  page.content = page.content.gsub(/\|\s*\n+{% if_version (.*) %}\n/) do |_match|
    "|\n{% if_version #{Regexp.last_match(1)} -%}\n"
  end
end
