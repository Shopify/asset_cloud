module AssetCloud
  class BucketIO
    def initialize(streamable)
      @streamable = streamable
    end

    def write(data)
      raise NotImplementedError
    end
    alias_method :<<, :write

    def close
      raise NotImplementedError
    end

    def delete
      raise NotImplementedError
    end
  end
end
