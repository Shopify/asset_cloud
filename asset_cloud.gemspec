# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{asset_cloud}
  s.version = "0.5.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Shopify"]
  s.date = %q{2009-07-03}
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
     "lib/asset_cloud/bucket.rb",
     "lib/asset_cloud/buckets/active_record_bucket.rb",
     "lib/asset_cloud/buckets/blackhole_bucket.rb",
     "lib/asset_cloud/buckets/bucket_chain.rb",
     "lib/asset_cloud/buckets/file_system_bucket.rb",
     "lib/asset_cloud/buckets/invalid_bucket.rb",
     "lib/asset_cloud/buckets/memory_bucket.rb",
     "lib/asset_cloud/buckets/versioned_memory_bucket.rb",
     "lib/asset_cloud/callbacks.rb",
     "lib/asset_cloud/free_key_locator.rb",
     "lib/asset_cloud/metadata.rb",
     "lib/asset_cloud/validations.rb",
     "spec/active_record_bucket_spec.rb",
     "spec/asset_spec.rb",
     "spec/base_spec.rb",
     "spec/blackhole_bucket_spec.rb",
     "spec/bucket_chain_spec.rb",
     "spec/callbacks_spec.rb",
     "spec/file_system_spec.rb",
     "spec/files/products/key.txt",
     "spec/files/versioned_stuff/foo",
     "spec/find_free_key_spec.rb",
     "spec/memory_bucket_spec.rb",
     "spec/regexp_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "spec/validations_spec.rb",
     "spec/versioned_memory_bucket_spec.rb"
  ]
  s.homepage = %q{http://github.com/Shopify/asset_cloud}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{An abstraction layer around arbitrary and diverse asset stores.}
  s.test_files = [
    "spec/active_record_bucket_spec.rb",
     "spec/asset_spec.rb",
     "spec/base_spec.rb",
     "spec/blackhole_bucket_spec.rb",
     "spec/bucket_chain_spec.rb",
     "spec/callbacks_spec.rb",
     "spec/file_system_spec.rb",
     "spec/find_free_key_spec.rb",
     "spec/memory_bucket_spec.rb",
     "spec/regexp_spec.rb",
     "spec/spec_helper.rb",
     "spec/validations_spec.rb",
     "spec/versioned_memory_bucket_spec.rb"
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
