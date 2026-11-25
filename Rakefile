# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

default_tasks = [:spec]

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
  default_tasks << :rubocop
rescue LoadError
  # RuboCop é opcional (grupo :lint do Gemfile).
end

task default: default_tasks
