class S3BucketIO < AssetCloud::BucketIO
  S3_MIN_PART_SIZE = 5.megabytes
  def initialize(streamable)
    @streamable = streamable
    @buffer = ""
  end

  def <<(data)
    @buffer << data
    add_part(data)
  end

  def close
    add_part(false)
    @streamable.complete(:remote_parts)
  end

  def delete
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
