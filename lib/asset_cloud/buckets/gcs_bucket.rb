# frozen_string_literal: true

module AssetCloud
  class GCSBucket < Bucket
    def ls(key = nil)
      key ? find_by_key!(key) : bucket.files
    end

    def read(key)
      file = find_by_key!(key)
      downloaded = file.download
      downloaded.rewind
      downloaded.read
    end

    def write(key, data, options = {})
      bucket.create_file(
        data,
        absolute_key(key),
        **options,
      )
    end

    def delete(key)
      file = find_by_key!(key)
      file.delete
    end

    def clear
      bucket.files.each(&:delete)
    end

    def stat(key)
      file = find_by_key!(key)
      Metadata.new(true, file.size, file.created_at, file.updated_at)
    rescue AssetCloud::AssetNotFoundError
      Metadata.new(false)
    end

    private

    def bucket
      @bucket ||= cloud.gcs_bucket
    end

    def absolute_key(key = nil)
      if key.to_s.starts_with?(path_prefix)
        key
      else
        args = [path_prefix]
        args << key.to_s if key
        args.join("/")
      end
    end

    def path_prefix
      @path_prefix ||= "s#{@cloud.url}"
    end

    def find_by_key!(key)
      file = bucket.file(absolute_key(key))

      raise AssetCloud::AssetNotFoundError, key unless file

      file
    end
  end
end
