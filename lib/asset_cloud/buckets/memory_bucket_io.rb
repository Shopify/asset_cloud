module AssetCloud
  class MemoryBucketIO < BucketIO
    def initialize(key, memory, &after_close_block)
      @memory = memory
      @key = key
      @streamable = StringIO.new
      @after_close_block = after_close_block
    end

    def write(data)
      @streamable.write(data)
    end

    def close
      @memory[@key] = @streamable.string
      @after_close_block.call(@key, @streamable)
    end
  end
end
