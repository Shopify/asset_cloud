require 'active_support'

# Core
require File.dirname(__FILE__) + '/asset_cloud/asset'
require File.dirname(__FILE__) + '/asset_cloud/metadata'
require File.dirname(__FILE__) + '/asset_cloud/bucket'
require File.dirname(__FILE__) + '/asset_cloud/buckets/active_record_bucket'
require File.dirname(__FILE__) + '/asset_cloud/buckets/blackhole_bucket'
require File.dirname(__FILE__) + '/asset_cloud/buckets/bucket_chain'
require File.dirname(__FILE__) + '/asset_cloud/buckets/file_system_bucket'
require File.dirname(__FILE__) + '/asset_cloud/buckets/invalid_bucket'
require File.dirname(__FILE__) + '/asset_cloud/buckets/memory_bucket'
require File.dirname(__FILE__) + '/asset_cloud/buckets/versioned_memory_bucket'
require File.dirname(__FILE__) + '/asset_cloud/base'


# Extensions
require File.dirname(__FILE__) + '/asset_cloud/free_key_locator'
require File.dirname(__FILE__) + '/asset_cloud/callbacks'
require File.dirname(__FILE__) + '/asset_cloud/validations'

require File.dirname(__FILE__) + '/asset_cloud/asset_extension'


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

  private

  def valid_key
    if key.blank?
      add_error "key cannot be empty"
    elsif key !~ AssetCloud::Base::VALID_PATHS
      add_error "#{key.inspect} contains illegal characters"
    end
  end
end

