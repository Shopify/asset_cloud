# frozen_string_literal: true

require "rails/railtie"
require "asset_cloud"

module AssetCloud
  class Railtie < Rails::Railtie
    config.eager_load_namespaces << AssetCloud
  end
end
