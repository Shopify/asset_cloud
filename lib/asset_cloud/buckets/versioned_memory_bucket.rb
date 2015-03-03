module AssetCloud
  class VersionedMemoryBucket < MemoryBucket

    def read(key)
      raise AssetCloud::AssetNotFoundError, key unless @memory.has_key?(key)
      read_version(key, latest_version(key))
    end

    def write(key, data)
      @memory[key] ||= []
      @memory[key] << data
      true
    end

    def read_version(key, version)
      @memory[key][version - 1]
    end

    def versions(key)
      (1..latest_version(key)).to_a
    end

    private

    def latest_version(key)
      @memory[key].size
    end
  end
end
