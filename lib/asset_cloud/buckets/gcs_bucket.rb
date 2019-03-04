# frozen_string_literal: true

module AssetCloud
  #:nodoc
  class GcsBucket < Bucket
    def ls(key = nil)
      if key
        cloud.gcs_bucket.files prefix: key
      else
        cloud.gcs_bucket.files
      end
    end

    def read(file_name, local_path)
      file = cloud.gcs_bucket.file file_name
      file.download local_path
    end

    def write(local_path, storage_path)
      cloud.gcs_bucket.create_file local_path, storage_path
    end

    def delete(key)
      file = cloud.gcs_bucket.file key
      file.delete
    end

    def clear
      cloud.gcs_bucket.files.each(&:delete)
    end
  end
end
