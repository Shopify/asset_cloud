require 'aws-sdk'

module AssetCloud
  class S3Bucket < Bucket
    def ls(key = nil)
      key = absolute_key(key)
      options = {}
      options.merge!(prefix: key) if key
      objects = cloud.s3_bucket(key).objects(options)

      objects.map { |o| cloud[relative_key(o.key)] }
    end

    def read(key, options = {})
      response = cloud.s3_bucket(key).object(absolute_key(key)).get(options)

      response.body.read
    rescue ::Aws::S3::Errors::ServiceError
      raise AssetCloud::AssetNotFoundError, key
    end

    def write(key, data, options = {})
      object = cloud.s3_bucket(key).object(absolute_key(key))

      object.put(options.merge(body: data))
    end

    def delete(key)
      object = cloud.s3_bucket(key).object(absolute_key(key))

      object.delete

      true
    end

    def stat(key)
      object = cloud.s3_bucket(key).object(absolute_key(key))

      AssetCloud::Metadata.new(true, object.content_length, nil, object.last_modified)
    rescue Aws::S3::Errors::NoSuchKey
      AssetCloud::Metadata.new(false)
    end

    protected
    def path_prefix
      @path_prefix ||= @cloud.url
    end

    def absolute_key(key = nil)
      if key.to_s.starts_with?(path_prefix)
        return key
      else
        args = [path_prefix]
        args << key.to_s if key
        args.join('/')
      end
    end

    def relative_key(key)
      key =~ /^#{path_prefix}\/(.+)/ ? $1 : key
    end
  end
end
