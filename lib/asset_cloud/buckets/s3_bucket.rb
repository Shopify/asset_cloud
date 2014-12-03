require 'aws'
require 'asset_cloud/s3_configuration'

module AssetCloud
  class S3Bucket < Bucket
    include S3Configuration

    def ls(key = nil)
      key = absolute_key(key)

      objects = S3Bucket.s3_bucket.objects
      objects = objects.with_prefix(key) if key

      objects.map { |o| cloud[relative_key(o.key)] }
    end

    def read(key)
      S3Bucket.s3_bucket.objects[absolute_key(key)].read
    rescue ::AWS::Errors::Base
      raise AssetCloud::AssetNotFoundError, key
    end

    def write(key, data, options = {})
      object = S3Bucket.s3_bucket.objects[absolute_key(key)]

      object.write(data, options)
    end

    def delete(key)
      object = S3Bucket.s3_bucket.objects[absolute_key(key)]

      object.delete rescue StandardError

      true
    end

    def stat(key)
      object = S3Bucket.s3_bucket.objects[absolute_key(key)]
      metadata = object.head

      AssetCloud::Metadata.new(true, metadata[:content_length], nil, metadata[:last_modified])
    rescue AWS::S3::Errors::NoSuchKey
      AssetCloud::Metadata.new(false)
    end

    protected
    def path_prefix
      @path_prefix ||= "s#{@cloud.url}"
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
      if key =~ /^#{path_prefix}\/(.+)/
        return $1
      else
        return key
      end
    end
  end
end
