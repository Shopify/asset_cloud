# frozen_string_literal: true

module AssetCloud
  class BucketChain < Bucket
    class << self
      # returns a new Bucket class which writes to each given Bucket
      # but only uses the first one for reading
      def chain(*klasses)
        Class.new(self) do
          attr_reader :chained_buckets

          define_method "initialize" do |cloud, name|
            super(cloud, name)
            @chained_buckets = klasses.map { |klass| klass.new(cloud, name) }
          end
        end
      end
    end

    def ls(key = nil)
      first_possible_bucket { |b| b.ls(key) }
    end

    def read(key)
      first_possible_bucket { |b| b.read(key) }
    end

    def stat(key = nil)
      first_possible_bucket { |b| b.stat(key) }
    end

    def read_version(key, version)
      first_possible_bucket { |b| b.read_version(key, version) }
    end

    def versions(key)
      first_possible_bucket { |b| b.versions(key) }
    end

    def write(key, data)
      every_bucket_with_transaction_on_key(key) { |b| b.write(key, data) }
    end

    def delete(key)
      every_bucket_with_transaction_on_key(key) { |b| b.delete(key) }
    end

    def respond_to_missing?(sym, *)
      @chained_buckets.any? { |b| b.respond_to?(sym) }
    end

    def method_missing(sym, *args)
      first_possible_bucket { |b| b.send(sym, *args) }
    end

    private

    def first_possible_bucket(&block)
      @chained_buckets.each do |bucket|
        return yield(bucket)
      rescue NoMethodError, NotImplementedError
        nil
      end
    end

    def every_bucket_with_transaction_on_key(key, i = 0, &block)
      return unless (bucket = @chained_buckets[i])

      old_value = begin
        bucket.read(key)
      rescue AssetCloud::AssetNotFoundError
        nil
      end
      result = yield(bucket)

      begin
        every_bucket_with_transaction_on_key(key, i + 1, &block)
        result
      rescue StandardError => e
        if old_value
          bucket.write(key, old_value)
        else
          bucket.delete(key)
        end
        raise e
      end
    end
  end
end
