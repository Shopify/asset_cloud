# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{asset_cloud}
  s.version = "2.2.4"

  s.authors = %w(Shopify)
  s.summary = %q{An abstraction layer around arbitrary and diverse asset stores.}
  s.description = %q{An abstraction layer around arbitrary and diverse asset stores.}

  s.email = %q{developers@shopify.com}
  s.homepage = %q{http://github.com/Shopify/asset_cloud}
  s.require_paths = %w(lib)

  s.files = `git ls-files`.split($/)
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  s.add_dependency 'activesupport'
  s.add_dependency 'class_inheritable_attributes'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'mocha'
  if RUBY_VERSION >= "2.0.0"
    s.add_development_dependency 'pry'
    s.add_development_dependency 'pry-byebug'
  end
end
