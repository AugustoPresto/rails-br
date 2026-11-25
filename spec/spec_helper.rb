# frozen_string_literal: true

require "bigdecimal"
require "simplecov"

SimpleCov.start do
  enable_coverage :branch
  add_filter "/spec/"
  add_filter "/gemfiles/"
  # Sobe para 95 quando os primeiros módulos entrarem (0.1.0).
  minimum_coverage 90
end

# Nos gemfiles do Appraisal o Rails está presente; no Ruby puro, não.
begin
  require "rails"
rescue LoadError
  nil
end

require "rails_br"

Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |file| require file }

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.order = :random
  Kernel.srand config.seed
end
