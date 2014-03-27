require 'securerandom'

module AssetCloud

  module FreeKeyLocator

    def find_free_key_like(key, options = {})
      # Check weather the suggested key name is free. If so we
      # simply return it.

      if !exist?(key) && !options[:force_uuid]
        key
      else
        ext         = File.extname(key)
        dirname     = File.dirname(key)
        base        = dirname == '.' ? File.basename(key, ext) : File.join(File.dirname(key), File.basename(key, ext))
        base        = base.gsub(/_[\h]{8}-[\h]{4}-4[\h]{3}-[\h]{4}-[\h]{12}/, "")

        # Attach UUID to avoid name collision
        key = "#{base}_#{SecureRandom.uuid}#{ext}"
        return key unless exist?(key)

        raise StandardError, 'Filesystem out of free filenames'
      end
    end
  end
end
