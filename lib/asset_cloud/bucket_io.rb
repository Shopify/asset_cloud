module AssetCloud
  class BucketIO
    def initialize(streamable)
      @streamable = streamable
    end

    def write(data)
      raise NotImplementedError
    end

    def <<(data)
      write(data)
    end

    def close
      raise NotImplementedError
    end
  end
end
