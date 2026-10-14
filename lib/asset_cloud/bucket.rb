# frozen_string_literal: true

module AssetCloud
  class AssetNotFoundError < StandardError
    def initialize(key, version = nil)
      super(version ? "Could not find version #{version} of asset #{key}" : "Could not find asset #{key}")
    end
  end

  class Bucket
    attr_reader :name
    attr_accessor :cloud

    def initialize(cloud, name)
      @cloud = cloud
      @name = name
    end

    def ls(key = nil)
      raise NotImplementedError
    end

    def read(key)
      raise NotImplementedError
    end

    def write(key, data)
      raise NotImplementedError
    end

    def delete(key)
      raise NotImplementedError
    end

    # versioning
    #
    # implement #read_version(key, version) and #versions(key) in subclasses
    def versioned?
      respond_to?(:read_version)
    end

    private

    def key_within_prefix?(key, prefix)
      return true if prefix.empty?

      key = key.to_s
      boundary = prefix.end_with?("/") ? prefix : "#{prefix}/"
      key == prefix || key.start_with?(boundary)
    end
  end
end
