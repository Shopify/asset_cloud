require 'aws-sdk'

module AssetCloud
  class S3Bucket < Bucket
    def ls(key = nil)
      key = absolute_key(key)

      options = {}
      options[:prefix] = key if key

      objects = cloud.s3_bucket(key).objects(options)
      objects.map { |o| cloud[relative_key(o.key)] }
    end

    def read(key, options = {})
      options[:range] = http_byte_range(options[:range]) if options[:range]

      object = cloud.s3_bucket(key)
        .object(absolute_key(key))
        .get(options)

      object.body.respond_to?(:read) ? object.body.read : object.body
    rescue ::Aws::Errors::ServiceError
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
      bucket_name = cloud.s3_bucket(key).name
      metadata = s3_client.head_object(bucket: bucket_name, key: absolute_key(key))

      AssetCloud::Metadata.new(true, metadata[:content_length], nil, metadata[:last_modified])
    rescue Aws::S3::Errors::NoSuchKey
      AssetCloud::Metadata.new(false)
    end

    private

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

    def http_byte_range(range)
      # follows https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35
      return "bytes=#{[range.begin, range.max].join('-')}" if range.is_a?(Range)
      range
    end

    def s3_client
      cloud.s3_connection.client
    end
  end
end
