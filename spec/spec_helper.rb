# frozen_string_literal: true

require 'pdfkit'

RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Use the specified formatter
  config.formatter = :documentation

  # Fail if no expectations were set
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.on_potential_false_positives = :raise
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # This setting enables warnings
  config.warnings = true

  # Share examples directory
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Seed for deterministic randomization
  config.order = :random
  Kernel.srand config.seed
end
