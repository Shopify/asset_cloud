                                                                                           
module AssetCloud
  class AssetNotFoundError < StandardError
    def initialize(key_or_message, message=false)
      super(message ? key_or_message : "Could not find asset #{key_or_message.to_s.inspect}")
    end
  end
  
  class Bucket
    attr_reader :name
    attr_accessor :cloud
    
    # returns a new Bucket class which writes to each given Bucket
    # but only uses the first one for reading
    def self.chain(*klasses)
      Class.new(self) do
        attr_reader :chained_buckets
        define_method 'initialize' do |cloud, name|
          super
          @chained_buckets = klasses.map {|klass| klass.new(cloud,name)}
        end
        def ls(key=nil)
          @chained_buckets.first.ls(key)
        end
        def read(key)
          @chained_buckets.first.read(key)
        end
        def write(key, data)
          @chained_buckets.each { |b| b.write(key, data)}
        end
        def delete(key)
          @chained_buckets.each { |b| b.delete(key)}
        end
      end
    end
    
    def initialize(cloud, name)
      @cloud, @name = cloud, name
    end
    
    def ls(key = nil)     
      raise NotImplementedError
    end                               

    def read(key)  
      raise NotImplementedError
    end          

    def write(key, data)       
      raise NotImplementedError
    end   

    def delete(key)
      raise NotImplementedError
    end
  end
end