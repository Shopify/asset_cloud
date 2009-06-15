module AssetCloud
  
  class AssetError < StandardError
  end
  
  class AssetNotSaved < AssetError
  end

  class Asset    
    include Comparable
    attr_accessor :key, :value, :cloud, :metadata
    attr_accessor :new_asset
    
    def initialize(cloud, key, value = nil, metadata = Metadata.non_existing)    
      @new_asset = true
      @cloud     = cloud
      @key       = key
      @value     = value                              
      @metadata  = metadata                                                 
      
      if @cloud.blank? 
        raise ArgumentError, "cloud is not a valid AssetCloud::Base"
      end
         
      yield self if block_given?    
    end                                                    
    
    def self.at(cloud, key, value = nil, metadata = nil, &block)
      file = self.new(cloud, key, value, metadata,  &block)
      file.new_asset = false
      file
    end
      
    def <=>(other)
      cloud.object_id <=> other.cloud.object_id && key <=> other.key
    end           
    
    def new_asset?
      @new_asset
    end              
    
    def dirname
      File.dirname(@key)
    end              
  
    def extname
      File.extname(@key)
    end
      
    def basename
      File.basename(@key)
    end        
  
    def basename_without_ext                              
      File.basename(@key, extname)
    end     
    
    def size
      metadata.size
    end
      
    def exist?
      metadata.exist?
    end       
    
    def created_at
      metadata.created_at
    end    
            
    def delete
      if new_asset?
        false
      else
        cloud.delete(key)
      end
    end
    
    def metadata
      @metadata ||= cloud.stat(key)
    end
  
    def value 
      @value ||= if new_asset?
        nil 
      else        
        cloud.read(key)
      end
    end
  
    def store                 
      unless @value.nil?    
        @new_asset = false
        @metadata = nil
        cloud.write(key, value)         
      end
    end               

    def store!                 
      store or raise AssetNotSaved
    end               
 
    def to_param
      basename
    end
  
    def handle
      basename.to_handle
    end                            
      
    def url    
      cloud.url_for key
    end                   
      
  
    def inspect
      "#<#{self.class.name}: #{key}>"
    end  
  end
end