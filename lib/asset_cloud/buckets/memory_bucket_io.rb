module AssetCloud
  class MemoryBucketIO < BucketIO
    def initialize(memory, key)
      @memory = memory
      @key = key
      @streamable = StringIO.new
    end

    def write(data)
      @streamable.write(data)
    end

    def close
      @memory[key] = @streamable.string
    end
  end
end
