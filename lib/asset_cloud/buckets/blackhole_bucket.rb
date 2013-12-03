module AssetCloud
  class BlackholeBucket < Bucket
    def ls(namespace = nil)
      []
    end

    def read(key)
      nil
    end

    def write(key, data)
      nil
    end

    def delete(key)
      nil
    end

    def stat(key)
      Metadata.new(false)
    end
  end
end
