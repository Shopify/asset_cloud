require 'aws'

module AssetCloud
  class S3Bucket < Bucket

   # s3 asset storage
   cattr_accessor :s3_connection, :s3_bucket_name, :default_s3_bucket
=begin
   def self.s3_connection

      AWS.eager_autoload!(AWS::S3) if Rails.application.config.eager_load

      AWS.config({
        access_key_id: config['access_key'],
        secret_access_key: config['secret_access_key'],
        use_ssl: true
      })
      AWS::S3.new(http_open_timeout: 20, http_read_timeout: 20)
    end

    def self.s3_bucket_name
      config['bucket']
    end
=end
    #TODO: Build this up
    def self.default_s3_bucket(reload=false)
      if @s3_bucket && !reload
        @s3_bucket
      else
        @s3_bucket = s3_connection.buckets[s3_bucket_name]
      end
    end

    def self.s3_bucket
      @s3_bucket ||= default_s3_bucket
    end

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

    def io(key, options={})
      object = S3Bucket.s3_bucket.objects[absolute_key(key)]
      S3BucketIO.new(object.multipart_upload(options))
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
