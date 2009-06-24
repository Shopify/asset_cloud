                                                                                           
module AssetCloud
  class AssetNotFoundError < StandardError
    def initialize(key_or_message, message=false)
      super(message ? key_or_message : "Could not find asset #{key_or_message.to_s.inspect}")
    end
  end
  
  class Bucket
    attr_reader :name
    attr_accessor :cloud
    
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