# frozen_string_literal: true

ENV['JEKYLL_ENV'] ||= 'test'

PROJECT_ROOT = File.expand_path('..', __dir__)

Dir.chdir(PROJECT_ROOT)

require 'jekyll'
require 'liquid'
require 'capybara'

Dir[File.join(PROJECT_ROOT, 'app/_plugins/{tags,blocks,lib,filters}/**/*.rb')].sort.each do |f|
  require f
end

Dir[File.join(__dir__, 'support/**/*.rb')].sort.each do |f|
  require f
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.order = :random
  config.warnings = true

  config.before(:suite) { JekyllSite.instance }
end
