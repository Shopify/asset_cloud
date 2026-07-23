# frozen_string_literal: true

require "addressable"
require "active_support"

# Core
require "asset_cloud/asset"
require "asset_cloud/metadata"
require "asset_cloud/bucket"
require "asset_cloud/buckets/active_record_bucket"
require "asset_cloud/buckets/blackhole_bucket"
require "asset_cloud/buckets/bucket_chain"
require "asset_cloud/buckets/file_system_bucket"
require "asset_cloud/buckets/invalid_bucket"
require "asset_cloud/buckets/memory_bucket"
require "asset_cloud/buckets/versioned_memory_bucket"

# Core entry-point class and external-SDK backends are autoloaded so that
# requiring asset_cloud does not load asset_cloud/base or pull in aws-sdk-s3
# (or the GCS SDK) at boot. They are eager-loaded in production by the Railtie.
module AssetCloud
  autoload :Base, "asset_cloud/base"
  autoload :S3Bucket, "asset_cloud/buckets/s3_bucket"
  autoload :GCSBucket, "asset_cloud/buckets/gcs_bucket"

  class << self
    def eager_load!
      _ = Base
      _ = S3Bucket
      _ = GCSBucket
    end
  end
end

# Extensions
require "asset_cloud/callbacks"
require "asset_cloud/validations"

require "asset_cloud/asset_extension"

AssetCloud::Asset.class_eval do
  include AssetCloud::Callbacks
  callback_methods :store, :delete

  include AssetCloud::Validations
  callback_methods :validate
  validate :valid_key

  def execute_callbacks(symbol, args)
    result = super
    result && @extensions.all? { |ext| ext.execute_callbacks(symbol, args) }
  end

  protected

  def valid_key_path?(key)
    key =~ AssetCloud::Base::VALID_PATHS
  end

  private

  def valid_key
    if key.blank?
      add_error("key cannot be empty")
    elsif !valid_key_path?(key)
      add_error("#{key.inspect} contains illegal characters")
    end
  end
end

if defined?(Rails::Railtie)
  require "asset_cloud/railtie"
end
