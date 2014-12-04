module AssetCloud
  class MemoryBucket < Bucket
    def initialize(*args)
      super
      @memory = {}
    end

    def ls(prefix=nil)
      results = []
      @memory.each do |k,v|
        results.push(cloud[k]) if prefix.nil? || k.starts_with?(prefix)
      end
      results
    end

    def read(key)
      raise AssetCloud::AssetNotFoundError, key unless @memory.has_key?(key)
      @memory[key]
    end

    def delete(key)
      @memory.delete(key)
    end

    def write(key, data)
      @memory[key] = data

      true
    end

    def stat(key)
      return Metadata.non_existing unless @memory.has_key?(key)

      Metadata.new(true, read(key).size)
    end
  end
end
