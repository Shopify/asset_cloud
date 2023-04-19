# frozen_string_literal: true

module AssetCloud
  class AssetError < StandardError
  end

  class AssetNotSaved < AssetError
  end

  class Asset
    include Comparable
    attr_accessor :key, :cloud, :new_asset
    attr_reader   :extensions
    attr_writer   :value, :metadata

    def initialize(cloud, key, value = nil, metadata = Metadata.non_existing)
      @new_asset = true
      @cloud     = cloud
      @key       = key
      @value     = value
      @metadata  = metadata

      apply_extensions

      if @cloud.blank?
        raise ArgumentError, "cloud is not a valid AssetCloud::Base"
      end

      yield self if block_given?
    end

    class << self
      def at(cloud, key, value = nil, metadata = nil, &block)
        file = new(cloud, key, value, metadata, &block)
        file.new_asset = false
        file
      end
    end

    def <=>(other)
      key <=> other.try(:key)
    end

    def new_asset?
      @new_asset
    end

    def relative_key
      @key.split("/", 2).last
    end

    def relative_key_without_ext
      relative_key.gsub(/\.[^.]+$/, "")
    end

    def dirname
      File.dirname(@key)
    end

    def extname
      File.extname(@key)
    end

    def format
      extname.sub(".", "")
    end

    def basename
      File.basename(@key)
    end

    def basename_without_ext
      File.basename(@key, extname)
    end

    def size
      metadata.size
    end

    def exist?
      metadata.exist?
    end

    def created_at
      metadata.created_at
    end

    def updated_at
      metadata.updated_at
    end

    def value_hash
      metadata.value_hash
    end

    def checksum
      metadata.checksum
    end

    def delete
      if new_asset?
        false
      else
        cloud.delete(key)
      end
    end

    def metadata
      @metadata ||= cloud.stat(key)
    end

    def value
      @value ||= if new_asset?
        nil
      else
        cloud.read(key)
      end
    end

    def store
      unless @value.nil?
        @new_asset = false
        @metadata = nil
        cloud.write(key, value)
      end
    end

    def store!
      store || raise(AssetNotSaved, "Validation failed: #{errors.join(", ")}")
    end

    def to_param
      basename
    end

    def handle
      basename.to_handle
    end

    def url(options = {})
      cloud.url_for(key, options)
    end

    def bucket_name
      @key.split("/").first
    end

    def bucket
      cloud.buckets[bucket_name.to_sym]
    end

    def inspect
      "#<#{self.class.name}: #{key}>"
    end

    # versioning

    def versioned?
      bucket.versioned?
    end

    def rollback(version)
      self.value = cloud.read_version(key, version)
      self
    end

    def versions
      cloud.versions(key)
    end

    def version_details
      cloud.version_details(key)
    end

    def method_missing(method, *args)
      if (extension = @extensions.find { |e| e.respond_to?(method) })
        extension.public_send(method, *args)
      else
        super
      end
    end

    def respond_to_missing?(method, include_all)
      @extensions.any? { |extension| extension.respond_to?(method, include_all) } || super
    end

    private

    def apply_extensions
      @extensions ||= []
      @cloud.asset_extension_classes_for_bucket(bucket_name).each do |ext|
        @extensions << ext.new(self) if ext.applies_to_asset?(self)
      end
    end
  end
end
