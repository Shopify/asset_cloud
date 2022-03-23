# -*- encoding: utf-8 -*-
# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "asset_cloud"
  s.version = "2.7.1"

  s.authors = ["Shopify"]
  s.summary = "An abstraction layer around arbitrary and diverse asset stores."
  s.description = "An abstraction layer around arbitrary and diverse asset stores."

  s.required_ruby_version = ">= 2.5.0"

  s.email = "developers@shopify.com"
  s.homepage = "http://github.com/Shopify/asset_cloud"
  s.require_paths = ["lib"]

  s.files = %x(git ls-files).split($/)
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  s.add_dependency("activesupport")

  s.metadata["allowed_push_host"] = "https://rubygems.org"

  s.add_development_dependency("pry")
  s.add_development_dependency("pry-byebug")
  s.add_development_dependency("rake")
  s.add_development_dependency("rspec")
  s.add_development_dependency("rubocop-shopify")
end
