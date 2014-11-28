module AssetCloud
  class S3BucketIO < BucketIO
    S3_MIN_PART_SIZE = 5.megabytes

    def initialize(key, streamable, &after_close_block)
      @key = key
      @streamable = streamable
      @after_close_block = after_close_block
      @buffer = ""
    end


    def write(data)
      @buffer << data
      add_part(data)
    end

    def close
      add_part(false)
      @streamable.complete(:remote_parts)
      @after_close_block.call(@key, @streamable)
    end

    def abort
      @streamable.abort
    end

    private
    def add_part(constrain_file_size = true)
      return if constrain_file_size && @buffer.size < S3_MIN_PART_SIZE
      if @buffer.size > 0
        @streamable.add_part(@buffer)
        @buffer = ""
      end
    end
  end
end
