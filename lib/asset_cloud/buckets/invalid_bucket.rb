module AssetCloud
  class InvalidBucketError < StandardError
  end

  class InvalidBucket < Bucket
    Error = "No such namespace: %s".freeze

    def ls(namespace)
      raise InvalidBucketError, Error % namespace
    end

    def read(key)
      raise InvalidBucketError, Error % key
    end

    def write(key, data)
      raise InvalidBucketError, Error % key
    end

    def delete(key)
      raise InvalidBucketError, Error % key
    end

    def stat(key)
      raise InvalidBucketError, Error % key
    end
  end
end
