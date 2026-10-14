# frozen_string_literal: true

require "stringio"

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
      # The GCS client treats String sources as local file paths, not content.
      if data.is_a?(String)
        if local_path?(data)
          warn("AssetCloud::GCSBucket#write treats String paths as literal content. " \
            "Pass an open File or IO object to upload file contents.")
        end
        data = StringIO.new(data)
      end

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

    def local_path?(data)
      File.exist?(data)
    rescue ArgumentError, Encoding::CompatibilityError
      false
    end

    def bucket
      @bucket ||= cloud.gcs_bucket
    end

    def absolute_key(key = nil)
      if key_within_prefix?(key, path_prefix)
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
