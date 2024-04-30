# -*- encoding: utf-8 -*-
# frozen_string_literal: true

require "English"
Gem::Specification.new do |s|
  s.name = "asset_cloud"
  s.version = "2.7.2"

  s.authors = ["Shopify"]
  s.summary = "An abstraction layer around arbitrary and diverse asset stores."
  s.description = "An abstraction layer around arbitrary and diverse asset stores."

  s.required_ruby_version = ">= 3.0.0"

  s.email = "developers@shopify.com"
  s.homepage = "http://github.com/Shopify/asset_cloud"
  s.require_paths = ["lib"]

  s.files = %x(git ls-files).split($INPUT_RECORD_SEPARATOR)

  s.add_dependency("activesupport")

  s.metadata["allowed_push_host"] = "https://rubygems.org"

  s.add_development_dependency("pry")
  s.add_development_dependency("pry-byebug")
  s.add_development_dependency("rake")
  s.add_development_dependency("rspec")
  s.add_development_dependency("rubocop-shopify")
end
