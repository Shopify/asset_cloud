module AssetCloud
   
  class MemoryBucket < Bucket
    
    def initialize(*args)
      super
      @memory = {}
    end

    def ls(key = nil)
      @memory.find_all do |key, value|
        key.left(key.size) == namespace
      end
    end

    def read(key)  
      raise AssetCloud::AssetNotFoundError, key unless @memory.has_key?(key)
      @memory[key]
    end          
    
    def delete(key)
      @memory.delete(key)
    end          

    def write(key, data)    
      @memory[key] = data

      true
    end

    def stat(key)
      return Metadata.non_existing unless @memory.has_key?(key)
          
      Metadata.new(true, @memory[key].size)
    end 

  end
  
  
end