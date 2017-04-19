require 'ostruct'

class MockS3Interface
  attr_reader :bucket_storage

  def initialize(aws_access_key_id = nil, aws_secret_access_key = nil, params = {})
    @buckets = {}
  end

  def buckets(**options)
    buckets = @buckets.values
    buckets = buckets.select { |v| v.start_with?(options[:prefix]) } if options[:prefix]
    buckets
  end

  def bucket(name)
    @buckets[name] ||= Bucket.new(name)
  end

  def client
    @client ||= Client.new(self)
  end

  class Client
    attr_reader :interface

    def initialize(interface)
      @interface = interface
    end

    def head_object(options = {})
      options = interface
        .bucket(options[:bucket])
        .object(options[:key])
        .get

      {
        content_length: options.body.size,
        last_modified: Time.parse("Mon Aug 27 17:37:51 UTC 2007")
      }
    end
  end

  class Bucket
    attr_reader :name
    def initialize(name)
      @name = name
      @storage = {}
    end

    def objects(**options)
      objects = @storage.values
      objects = objects.select { |v| v.start_with?(options[:prefix]) } if options[:prefix]
      objects
    end

    def object(key)
      @storage[key] ||= NullS3Object.new(self, key)
    end

    def put_object(options = {})
      options = options.dup
      options[:body] = options[:body].force_encoding(Encoding::BINARY)

      key = options.delete(:key)

      @storage[key] = S3Object.new(self, key, options)
      true
    end

    def clear
      @storage = {}
    end

    def inspect
      "#<MockS3Interface::Bucket @name=#{@name.inspect}, @storage.keys = #{@storage.keys.inspect}>"
    end
  end

  class NullS3Object
    attr_reader :key
    def initialize(bucket, key)
      @bucket = bucket
      @key = key
    end

    def get(*)
      raise Aws::S3::Errors::NoSuchKey(nil, nil)
    end

    def delete(*)
    end

    def put(options = {})
      @bucket.put_object(options.merge(key: @key))
    end
  end

  class S3Object
    attr_reader :key, :options

    def initialize(bucket, key, options = {})
      @bucket = bucket
      @key = key
      @options = options
    end

    def delete
      @bucket.delete(@key)
      true
    end

    def get(*)
      OpenStruct.new(options)
    end

    def put(options = {})
      @bucket.put_object(options.merge(key: @key))
    end
  end
end
