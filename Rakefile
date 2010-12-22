require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
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

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "asset_cloud"
    gemspec.summary = "An abstraction layer around arbitrary and diverse asset stores."
    gemspec.email = "developers@shopify.com"
    gemspec.homepage = "http://github.com/Shopify/asset_cloud"
    gemspec.description = "An abstraction layer around arbitrary and diverse asset stores."
    gemspec.authors = ["Shopify"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end