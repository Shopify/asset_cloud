# frozen_string_literal: true

module AssetCloud
  class InvalidBucketError < StandardError
  end

  class InvalidBucket < Bucket
    ERROR = "No such namespace: %s"
    private_constant :ERROR

    def ls(namespace)
      raise InvalidBucketError, ERROR % namespace
    end

    def read(key)
      raise InvalidBucketError, ERROR % key
    end

    def write(key, data)
      raise InvalidBucketError, ERROR % key
    end

    def delete(key)
      raise InvalidBucketError, ERROR % key
    end

    def stat(key)
      raise InvalidBucketError, ERROR % key
    end
  end
end
