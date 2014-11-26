require 'active_support'

# Core
require 'asset_cloud/asset'
require 'asset_cloud/metadata'
require 'asset_cloud/bucket'
require 'asset_cloud/bucket_io'
require 'asset_cloud/buckets/active_record_bucket'
require 'asset_cloud/buckets/blackhole_bucket'
require 'asset_cloud/buckets/bucket_chain'
require 'asset_cloud/buckets/file_system_bucket'
require 'asset_cloud/buckets/file_bucket_io'
require 'asset_cloud/buckets/invalid_bucket'
require 'asset_cloud/buckets/memory_bucket'
require 'asset_cloud/buckets/memory_bucket_io'
require 'asset_cloud/buckets/versioned_memory_bucket'
require 'asset_cloud/buckets/s3_bucket'
require 'asset_cloud/buckets/s3_bucket_io'
require 'asset_cloud/base'


# Extensions
require 'asset_cloud/free_key_locator'
require 'asset_cloud/callbacks'
require 'asset_cloud/validations'

require 'asset_cloud/asset_extension'

AssetCloud::Base.class_eval do
  include AssetCloud::FreeKeyLocator
  include AssetCloud::Callbacks
  callback_methods :write, :delete
  explicit_after_callback_methods :io_close
end

AssetCloud::Asset.class_eval do
  include AssetCloud::Callbacks
  callback_methods :store, :delete

  include AssetCloud::Validations
  callback_methods :validate
  validate :valid_key

  def execute_callbacks(symbol, args)
    super
    @extensions.each {|ext| ext.execute_callbacks(symbol, args)}
  end

  private

  def valid_key
    if key.blank?
      add_error "key cannot be empty"
    elsif key !~ AssetCloud::Base::VALID_PATHS
      add_error "#{key.inspect} contains illegal characters"
    end
  end
end
