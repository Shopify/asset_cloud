module AssetCloud
  class FileBucketIO < BucketIO
    def initialize(streamable)
      @streamable = streamable
    end

    def write(data)
      @streamable.write(data)
    end

    def close
      @streamable.close
    end
  end
end
