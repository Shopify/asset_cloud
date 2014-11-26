module AssetCloud
  class FileBucketIO < BucketIO
    def write(data)
      @streamable.write(data)
    end
    alias_method :<<, :write

    def close
      @streamable.close
    end
  end
end
