module AssetCloud
  class AssetExtension
    class AssetMismatch < StandardError
    end
    def store; true; end
    def delete; true; end

    include AssetCloud::Callbacks
    include AssetCloud::Validations

    callback_methods :store, :delete, :validate

    attr_reader :asset
    delegate :add_error, :to => :asset

    class_attribute :extnames

    def self.applies_to(*args)
      extnames = args.map do |arg|
        arg = arg.to_s.downcase
        arg = ".#{arg}" unless arg.starts_with?('.')
        arg
      end
      self.extnames = extnames
    end

    def self.applies_to_asset?(asset)
      extnames = self.extnames || []
      extnames.each do |extname|
        return true if asset.key.downcase.ends_with?(extname)
      end
      false
    end

    def initialize(asset)
      unless self.class.applies_to_asset?(asset)
        raise AssetMismatch, "Instances of #{self.class.name} cannot be applied to asset #{asset.key.inspect}"
      end
      @asset = asset
    end
  end
end
