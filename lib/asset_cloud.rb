require 'active_support'

# Core
require 'asset_cloud/asset'
require 'asset_cloud/metadata'
require 'asset_cloud/bucket'
require 'asset_cloud/buckets/active_record_bucket'
require 'asset_cloud/buckets/blackhole_bucket'
require 'asset_cloud/buckets/bucket_chain'
require 'asset_cloud/buckets/file_system_bucket'
require 'asset_cloud/buckets/invalid_bucket'
require 'asset_cloud/buckets/memory_bucket'
require 'asset_cloud/buckets/versioned_memory_bucket'
require 'asset_cloud/base'

#S3
require 'asset_cloud/buckets/s3_bucket'

# Extensions
require 'asset_cloud/free_key_locator'
require 'asset_cloud/callbacks'
require 'asset_cloud/validations'

require 'asset_cloud/asset_extension'

AssetCloud::Base.class_eval do
  include AssetCloud::FreeKeyLocator
  include AssetCloud::Callbacks
  callback_methods :write, :delete
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

  protected

  def valid_key_path?(key)
    key =~ AssetCloud::Base::VALID_PATHS
  end

  private

  def valid_key
    if key.blank?
      add_error "key cannot be empty"
    elsif !valid_key_path?(key)
      add_error "#{key.inspect} contains illegal characters"
    end
  end
end
