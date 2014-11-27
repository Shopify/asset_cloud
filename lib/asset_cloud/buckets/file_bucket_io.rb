module AssetCloud
  class FileBucketIO < BucketIO
    def write(data)
      @streamable.write(data)
    end

    def close
      @streamable.close
    end
  end
end
