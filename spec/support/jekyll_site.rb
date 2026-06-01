# frozen_string_literal: true

require 'yaml'

module JekyllSite
  def self.instance
    @instance ||= build
  end

  def self.build
    config = Jekyll.configuration(
      YAML.safe_load(
        File.read(File.expand_path('../../jekyll.yml', __dir__)),
        aliases: true
      ).merge(
        'source' => File.expand_path('../fixtures/app', __dir__),
        'destination' => File.expand_path('../fixtures/dist', __dir__),
        'quiet' => true,
        'git_branch' => 'main'
      )
    )
    Jekyll::Site.new(config)
  end
end
