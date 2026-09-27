# frozen_string_literal: true

require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # no rspec available
end

desc 'Regenerate spec/api from the document'
task :generate do
  sh 'bin/generate-specs'
end

desc 'Lint the document the way CI does'
task :lint do
  sh 'vacuum lint -d monzo_api.yaml --fail-severity error'
end

task default: %i[lint spec]
