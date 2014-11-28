module AssetCloud
  class FileBucketIO < BucketIO
    def initialize(key, streamable, &after_close_block)
      @key = key
      @streamable = streamable
      @after_close_block = after_close_block
    end

    def write(data)
      @streamable.write(data)
    end

    def close
      @streamable.close
      @after_close_block.call(@key, @streamable)
    end
  end
end
