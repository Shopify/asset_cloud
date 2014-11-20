module AssetCloud
  class BucketIO
    def initialize(streamable)
      @streamable = streamable
    end

    def <<(data)
      raise NotImplementedError
    end

    def close
      raise NotImplementedError
    end

    def delete
      raise NotImplementedError
    end
    alias_method :abort, :delete
  end
end
