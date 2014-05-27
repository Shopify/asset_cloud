require 'bundler/gem_tasks'
require 'rspec'

require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'rspec/core/rake_task'

desc 'Default: run unit tests.'
task :default => [:spec]

desc "Run all spec examples"
RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = ['--color']
end

desc 'Generate documentation for the asset_cloud plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'AssetCloud'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
