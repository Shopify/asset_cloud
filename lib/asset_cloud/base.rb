
module AssetCloud
  
  class IllegalPath < StandardError
  end

  class Base    
    cattr_accessor :logger
    
    VALID_PATHS = /^[a-z0-9][a-z0-9_\-\/]+([a-z0-9][\w\-\ \.]*\.\w{2,6})?$/i
  
    attr_accessor :url, :root        
    
    class_inheritable_accessor :root_bucket_class
    self.root_bucket_class = FileSystemBucket
    class_inheritable_accessor :root_asset_class
    self.root_asset_class  = Asset
    
    class_inheritable_hash :bucket_classes
    self.bucket_classes = {}
    class_inheritable_hash :asset_classes
    self.asset_classes = {}
    
    def self.bucket(*args)      
      asset_class = if args.last.is_a? Hash
        args.pop[:asset_class]
      end
      
      if args.last.is_a? Class
        bucket_class = args.pop
      else
        raise ArgumentError, 'requires a bucket class'
      end

      if bucket_name = args.first
        self.bucket_classes[bucket_name.to_sym] = bucket_class
        self.asset_classes[bucket_name.to_sym]  = asset_class if asset_class
      else
        self.root_bucket_class = bucket_class
        self.root_asset_class  = asset_class if asset_class
      end
    end    

    def buckets
      @buckets ||= Hash.new do |hash, key|
        if klass = self.class.bucket_classes[key] 
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
    
    def find(key)
      returning asset_at(key) do |asset|
        asset.value
      end
    end
    
    def asset_at(*args)
      check_key_for_errors(args.first)
      
      asset_class_for(args.first).at(self, *args)        
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
      asset_class_for(key).new(self, key, value, Metadata.non_existing, &block)        
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
      bucket = buckets[bucket_symbol_for_key(key)]
      bucket ? bucket : root_bucket  
    end
                      
    def []=(key, value)
      asset = self[key]
      asset.value = value
      asset.store
    end

    def [](key)
      asset_at(key)
    end
    
    # versioning
    
    def read_version(key, version)
      logger.info { "  [#{self.class.name}] Reading from #{key} at version #{version}" } if logger      
      bucket_for(key).read_version(key, version)
    end
    
    def versions(key)
      logger.info { "  [#{self.class.name}] Getting all versions for #{key}" } if logger      
      bucket_for(key).versions(key)
    end
       
    protected
    
    def asset_class_for(key)
      self.class.asset_classes[bucket_symbol_for_key(key)] || self.class.root_asset_class
    end
    
    def bucket_symbol_for_key(key)
      $1.to_sym if key =~ /^(\w+)(\/|$)/
    end
    
    def root_bucket
      @default_bucket ||= self.class.root_bucket_class.new(self, '')
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