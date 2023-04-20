# frozen_string_literal: true

require "aws-sdk-s3"

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
      options = options.dup

      options[:range] = http_byte_range(options[:range]) if options[:range]

      bucket = cloud.s3_bucket(key)
      if (encryption_key = options.delete(:encryption_key))
        bucket = encrypted_bucket(bucket, encryption_key)
      end

      object = bucket.object(absolute_key(key)).get(options)

      object.body.respond_to?(:read) ? object.body.read : object.body
    rescue ::Aws::Errors::ServiceError
      raise AssetCloud::AssetNotFoundError, key
    end

    def write(key, data, options = {})
      options = options.dup

      bucket = cloud.s3_bucket(key)
      if (encryption_key = options.delete(:encryption_key))
        bucket = encrypted_bucket(bucket, encryption_key)
      end

      object = bucket.object(absolute_key(key))
      object.put(options.merge(body: data))
    end

    def delete(key)
      object = cloud.s3_bucket(key).object(absolute_key(key))
      object.delete
      true
    end

    def stat(key)
      bucket = cloud.s3_bucket(key)
      metadata = bucket.client.head_object(bucket: bucket.name, key: absolute_key(key))

      AssetCloud::Metadata.new(true, metadata[:content_length], nil, metadata[:last_modified])
    rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NotFound
      AssetCloud::Metadata.new(false)
    end

    private

    def encrypted_bucket(source_bucket, key)
      Aws::S3::Resource.new(
        client: Aws::S3::Encryption::Client.new(
          client: source_bucket.client,
          encryption_key: key,
        ),
      ).bucket(source_bucket.name)
    end

    def path_prefix
      @path_prefix ||= @cloud.url
    end

    def absolute_key(key = nil)
      if key.to_s.starts_with?(path_prefix)
        key
      else
        args = [path_prefix]
        args << key.to_s if key
        args.join("/")
      end
    end

    def relative_key(key)
      key =~ %r{^#{path_prefix}/(.+)} ? Regexp.last_match(1) : key
    end

    def http_byte_range(range)
      # follows https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35
      return "bytes=#{[range.begin, range.max].join("-")}" if range.is_a?(Range)

      range
    end
  end
end
