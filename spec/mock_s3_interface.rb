class MockS3Interface
  attr_reader :bucket_storage

  def initialize(aws_access_key_id=nil, aws_secret_access_key=nil, params={})
    @bucket_storage = {}
  end

  def buckets
    @bucket_collection ||= BucketCollection.new(self)
  end

  def client
    @client ||= Client.new
  end

  class Client
  end

  class BucketCollection
    def initialize(interface)
      @interface = interface
    end

    def [](name)
      @interface.bucket_storage[name] ||= Bucket.new(name)
    end
  end

  class Bucket
    attr_reader :name
    def initialize(name)
      @name = name
      @storage = {}
      @storage_options = {}
    end

    def with_prefix(prefix)
      keys = @storage
      keys = keys.select {|k,v| k.starts_with?(prefix)}
      keys.map {|k,v| S3Object.new(self, k, v)}
    end

    def objects
      Collection.new(self, @storage.keys)
    end

    def get(key)
      if @storage.key?(key)
        @storage[key]
      else
        raise AWS::S3::Errors::NoSuchKey.new(nil, nil)
      end
    end

    def get_options(key)
      if @storage_options.key?(key)
        @storage_options[key]
      else
        raise AWS::S3::Errors::NoSuchKey.new(nil, nil)
      end
    end

    def put(key, data, options={})
      @storage[key] = data.dup.force_encoding(Encoding::BINARY)
      @storage_options[key] = options.dup
      true
    end

    def delete(key)
      @storage.delete(key)
      true
    end

    def clear
      @storage = {}
    end

    def inspect
      "#<MockS3Interface::Bucket @name=#{@name.inspect}, @storage.keys = #{@storage.keys.inspect}>"
    end
  end

  class Collection
    include Enumerable

    def initialize(bucket, objects)
      @bucket = bucket
      @objects = objects
    end

    def with_prefix(prefix)
      self.class.new(@bucket, @objects.select {|k| k.start_with?(prefix)})
    end

    def [](name)
      S3Object.new(@bucket, name)
    end

    def each
      @objects.each { |e| yield S3Object.new(@bucket, e) }
    end
  end

  class S3Object
    attr_reader :key

    def initialize(bucket, key, data=nil)
      @bucket = bucket
      @key = key
    end

    def delete
      @bucket.delete(@key)
    end

    def read(headers={})
      @bucket.get(@key)
    end

    def options()
      @bucket.get_options(@key)
    end

    def write(data, options={})
      @bucket.put(@key, data, options)
    end

    def multipart_upload(options = {})
      MockMultipartUpload.new(@bucket, @key)
    end

    def url_for(permission, options={})
      if options[:secure]
        URI.parse("https://www.youtube.com/watch?v=oHg5SJYRHA0")
      else
        URI.parse("http://www.youtube.com/watch?v=oHg5SJYRHA0")
      end
    end

    def head
      {
        content_length: read.size,
        last_modified: Time.parse("Mon Aug 27 17:37:51 UTC 2007")
      }
    end
  end

  class MockMultipartUpload
    def initialize(bucket, key)
      @bucket =bucket
      @key = key
      @data = ""
    end

    def add_part(data)
      @data << data
    end

   def abort
      @bucket.delete(@key)
   end

   def complete(arg)
      @bucket.put(@key, @data, {})
    end
  end
end
