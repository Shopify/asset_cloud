module AssetCloud
  module Configuration
    extend ActiveSupport::Concern

    included do
      # AWS S3
      add_config :load_aws
      add_config :aws_s3_connection
      add_config :s3_bucket_name
      add_config :aws_access_key_id
      add_config :aws_secret_access_key
      add_config :use_ssl
      add_config :aws_open_timeout
      add_config :aws_read_timeout
    end

    module ClassMethods
      def add_config(name)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def self.eager_load_aws(value)
            AWS.eager_autoload!(AWS::S3) if load_aws
          end
          def self.#{name}(value=nil)
            @#{name} = value if value
            eager_load_aws(value) if value && '#{name}' == 'load_aws'
            return @#{name} if self.object_id == #{self.object_id} || defined?(@#{name})
            name = superclass.#{name}
            return nil if name.nil? && !instance_variable_defined?("@#{name}")
            @#{name} = name && !name.is_a?(Module) && !name.is_a?(Symbol) && !name.is_a?(Numeric) && !name.is_a?(TrueClass) && !name.is_a?(FalseClass) ? name.dup : name
          end
          def self.#{name}=(value)
            eager_load_aws(value) if '#{name}' == 'load_aws'
            @#{name} = value
          end
          def #{name}=(value)
            self.class.eager_load_aws(value) if '#{name}' == 'load_aws'
            @#{name} = value
          end
          def #{name}
            value = @#{name} if instance_variable_defined?(:@#{name})
            value = self.class.#{name} unless instance_variable_defined?(:@#{name})
            if value.instance_of?(Proc)
              value.arity >= 1 ? value.call(self) : value.call
            else
              value
            end
          end
        RUBY
      end

      def configure
        yield self
      end

      def reset_config
        self.load_aws = nil
        self.aws_s3_connection = nil
        self.s3_bucket_name = nil
        self.aws_access_key_id = nil
        self.aws_secret_access_key = nil
        self.use_ssl = nil
        self.aws_open_timeout = nil
        self.aws_read_timeout = nil
        @s3_bucket = nil
      end


      def s3_connection
        return aws_s3_connection if aws_s3_connection

        AWS.config({
          access_key_id: aws_access_key_id,
          secret_access_key: aws_secret_access_key,
          use_ssl: defined?(use_ssl) ? use_ssl : true
        })
        open_timeout = defined?(aws_open_timeout) ? aws_open_timeout : 5
        read_timeout = defined?(aws_read_timeout) ? aws_read_timeout : 5

        aws_s3_connection = AWS::S3.new(http_open_timeout: open_timeout, http_read_timeout: read_timeout)
      end

      def s3_bucket(reload = false)
        if @s3_bucket && !reload
          @s3_bucket
        else
          @s3_bucket = s3_connection.buckets[s3_bucket_name]
        end
      end
    end
  end
end
