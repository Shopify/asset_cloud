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

    def write(key, data)
      bucket.create_file(data, full_path(key))
    end

    def delete(key)
      file = find_by_key!(key)
      file.delete
    end

    def clear
      bucket.files.each(&:delete)
    end

    def stat(key)
      begin
        file = find_by_key!(key)
        Metadata.new(true, file.size, file.created_at, file.updated_at)
      rescue AssetCloud::AssetNotFoundError
        Metadata.new(false)
      end
    end

    private

    def bucket
      @bucket ||= cloud.gcs_bucket
    end

    def full_path(key)
      "s#{cloud.url}/#{key}"
    end

    def find_by_key!(key)
      file = bucket.file(full_path(key))

      raise AssetCloud::AssetNotFoundError, key unless file

      file
    end
  end
end
