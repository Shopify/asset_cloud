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
require "asset_cloud/base"

# GCS
require "asset_cloud/buckets/gcs_bucket"

# Extensions
require "asset_cloud/free_key_locator"
require "asset_cloud/callbacks"
require "asset_cloud/validations"

require "asset_cloud/asset_extension"

module AssetCloud
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload_under "buckets" do
      autoload :S3Bucket
    end
  end

  Base.class_eval do
    include FreeKeyLocator
    include Callbacks
    callback_methods :write, :delete
  end

  Asset.class_eval do
    include Callbacks
    callback_methods :store, :delete

    include Validations
    callback_methods :validate
    validate :valid_key

    def execute_callbacks(symbol, args)
      result = super
      result && @extensions.all? { |ext| ext.execute_callbacks(symbol, args) }
    end

    protected

    def valid_key_path?(key)
      key =~ Base::VALID_PATHS
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
end
