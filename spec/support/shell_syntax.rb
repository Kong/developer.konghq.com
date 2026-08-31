# frozen_string_literal: true

require 'open3'

def bash_code_block(rendered, lang: 'bash')
  rendered[/```#{lang}\n(.*?)\n```/m, 1]
end

def validate_bash_syntax!(script)
  _stdout, stderr, status = Open3.capture3('bash', '-n', stdin_data: script)
  return if status.success?

  raise "Invalid bash syntax:\n#{script}\n\n#{stderr}"
end
