module AssetCloud
  class FileBucketIO < BucketIO
    def <<(data)
      @streamable << data
    end

    def close
      @streamable.close
    end

    def delete
      File.delete(@streamable.path) if File.exists?(@streamable.path)
    end
    alias_method :abort, :delete
  end
end
