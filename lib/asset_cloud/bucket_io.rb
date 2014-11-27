module AssetCloud
  class BucketIO
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
