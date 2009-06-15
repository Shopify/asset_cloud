module AssetCloud    
   
  module FreeKeyLocator
     
    def find_free_key_like(key, options = {})                                                            
      # Check weather the suggested key name is free. If so we
      # simply return it.                 
      
      if not exist?(key)
        key
      else                                       
                                                                      
        ext         = File.extname(key)
        dirname     = File.dirname(key)
        base        = dirname == '.' ? File.basename(key, ext) : File.join(File.dirname(key), File.basename(key, ext))
        count       = base.scan(/\d+$/).flatten.first.to_i
        base        = base.gsub(/([\-\_]?)\d+$/,'')  
        separator   = $1 || '_'
        

        # increase the count until you find a unused key
        10.times do                              
          count += 1
          key = "#{base}#{separator}#{count}#{ext}"
          return key unless exist?(key)
        end

        # Ok we have to go random here...
        100.times do                              
          count += rand(9999999)
          key = "#{base}#{separator}#{count}#{ext}"
          return key unless exist?(key)
        end

        raise StandardError, 'Filesystem out of free filenames' 
      end
    end
  end
end