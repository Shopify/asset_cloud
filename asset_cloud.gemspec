# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{asset_cloud}
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Shopify"]
  s.date = %q{2009-06-16}
  s.description = %q{An abstraction layer around arbitrary and diverse asset stores.}
  s.email = %q{developers@shopify.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "CHANGELOG",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "asset_cloud.gemspec",
     "init.rb",
     "install.rb",
     "lib/asset_cloud.rb",
     "lib/asset_cloud/asset.rb",
     "lib/asset_cloud/base.rb",
     "lib/asset_cloud/blackhole_bucket.rb",
     "lib/asset_cloud/bucket.rb",
     "lib/asset_cloud/callbacks.rb",
     "lib/asset_cloud/file_system_bucket.rb",
     "lib/asset_cloud/free_key_locator.rb",
     "lib/asset_cloud/invalid_bucket.rb",
     "lib/asset_cloud/memory_bucket.rb",
     "lib/asset_cloud/metadata.rb",
     "spec/asset_spec.rb",
     "spec/base_spec.rb",
     "spec/blackhole_bucket_spec.rb",
     "spec/bucket_spec.rb",
     "spec/callbacks_spec.rb",
     "spec/file_system_spec.rb",
     "spec/files/products/key.txt",
     "spec/find_free_key_spec.rb",
     "spec/memory_bucket_spec.rb",
     "spec/regexp_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/Shopify/asset_cloud}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{An abstraction layer around arbitrary and diverse asset stores.}
  s.test_files = [
    "spec/asset_spec.rb",
     "spec/base_spec.rb",
     "spec/blackhole_bucket_spec.rb",
     "spec/bucket_spec.rb",
     "spec/callbacks_spec.rb",
     "spec/file_system_spec.rb",
     "spec/find_free_key_spec.rb",
     "spec/memory_bucket_spec.rb",
     "spec/regexp_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
