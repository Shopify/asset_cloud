# -*- encoding: utf-8 -*-
 
Gem::Specification.new do |s|
  s.name = %q{asset_cloud}
  s.version = "0.5.0"
  s.authors = ["Shopify"]
  s.date = %q{2009-06-16}
  s.description = %q{= AssetCloud

An abstraction layer around arbitrary and diverse asset stores.

== Installation

=== as a Gem

    gem install Shopify-asset_cloud -s http://gems.github.com

=== as a Rails plugin

    script/plugin install git://github.com/Shopify/asset_cloud.git

== Copyright

Copyright (c) 2008-2009 Tobias Lütke & Jaded Pixel, Inc. Released under the MIT license (see LICENSE for details).
}
  s.email = %q{developers@shopify.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = Dir['lib/**/*.rb'] + [
    ".document",
    "CHANGELOG",
    "LICENSE",
    "README.rdoc"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/Shopify/asset_cloud}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{assetcloud}
  s.summary = %q{An abstraction layer around arbitrary and diverse asset stores.}
  s.add_dependency('activesupport', [">= 2.2.2"])
end