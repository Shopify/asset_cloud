require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/rake/spectask'

desc 'Default: run unit tests.'
task :default => [:spec]

desc "Run all spec examples"
Spec::Rake::SpecTask.new do |t|
  t.libs << "spec"
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--options', %\"#{File.dirname(__FILE__)}/spec/spec.opts"\]
end

desc 'Generate documentation for the asset_cloud plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'AssetCloud'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
