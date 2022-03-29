# frozen_string_literal: true

require "rubygems"
require "rspec"
require "pry-byebug" if RUBY_VERSION >= "2.0.0"
require "active_support/all"
$LOAD_PATH << File.dirname(__FILE__) + "/../lib"
require "asset_cloud"
require "asset_cloud/buckets/s3_bucket"
require "asset_cloud/buckets/gcs_bucket"
