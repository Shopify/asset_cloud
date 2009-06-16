
module AssetCloud
  
  class IllegalPath < StandardError
  end

  class Base    
    cattr_accessor :logger       
    
    VALID_PATHS = /^[a-z0-9][a-z0-9_\-\/]+([a-z0-9][\w\-\ \.]*\.\w{2,6})?$/i
  
    attr_accessor :url, :root        
    
    class_inheritable_accessor :root_bucket
    self.root_bucket = FileSystemBucket
      
    
    class_inheritable_hash :buckets
    self.buckets = {}
    
    def self.bucket(*args)      
      if args.last.is_a? Class
        klass       = args.pop
      else
        raise ArgumentError, 'require a bucket class as last parameter'
      end

      if bucket_name = args.first
        self.buckets[bucket_name.to_sym] = klass
      else
        self.root_bucket = klass
      end
    end    

    def buckets
      @buckets ||= Hash.new do |hash, key|
        if klass = self.class.buckets[key] 
          hash[key] = klass.new(self, key)
        else       
          hash[key] = nil
        end
      end
    end
  
    def initialize(root, url = '/')            
      @root, @url = root, url
    end             
  
    def url_for(key, secure = false)
      File.join(@url, key)
    end                         

    def path_for(key)
      File.join(path, key) 
    end              
    
    def path
      root
    end
    
    def asset_at(key)
      check_key_for_errors(key)
      
      Asset.at(self, key)        
    end            
  
    def move(source, destination)
      return if source == destination                   

      object = copy(source, destination)                      
      asset_at(source).delete
      object
    end       
  
    def copy(source, destination)
      return if source == destination                   

      object = build(destination, read(source))
      object.store
      object
    end    
  
    def build(key, value = nil, &block)   
      logger.info { "  [#{self.class.name}] Building asset #{key}" } if logger
      Asset.new(self, key, value, Metadata.non_existing, &block)        
    end            
    
    def write(key, value)
      check_key_for_errors(key)
      logger.info { "  [#{self.class.name}] Writing #{value.size} bytes to #{key}" } if logger

      bucket_for(key).write(key, value)
    end           
    
    def read(key)                      
      logger.info { "  [#{self.class.name}] Reading from #{key}" } if logger      
      
      bucket_for(key).read(key)
    end
    
    def stat(key)
      logger.info { "  [#{self.class.name}] Statting #{key}" } if logger      

      bucket_for(key).stat(key)
    end                   
    
    def ls(key)  
      logger.info { "  [#{self.class.name}] Listing objects in #{key}" } if logger      
      
      bucket_for(key).ls(key)
    end
    
    def exist?(key)      
      if fp = stat(key)
        fp.exist?
      else
        false
      end
    end      
    
    def delete(key)   
      logger.info { "  [#{self.class.name}] Deleting #{key}" } if logger      
                 
      bucket_for(key).delete(key)
    end

    def bucket_for(key)     
      bucket = buckets[$1.to_sym] if key =~ /^(\w+)(\/|$)/
      bucket ? bucket : root_bucket  
    end
                      
    def []=(key, value)
      write(key, value)
    end

    def [](key)
      asset_at(key)
    end
       
    protected                    
    
    def root_bucket
      @default_bucket ||= self.class.root_bucket.new(self, '')
    end
    
    def check_key_for_errors(key)
      raise IllegalPath, "key cannot be empty" if key.blank?
      raise IllegalPath, "#{key.inspect} contains illegal characters" unless key =~ VALID_PATHS      
    rescue => e
      logger.info { "  [#{self.class.name}]   bad key #{e.message}" } if logger      
      raise      
    end
    
  end
end