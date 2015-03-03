module AssetCloud

  class FileSystemBucket < Bucket

    def ls(key = nil)
      objects = []
      base_path = File.join(path_for(key), '*')

      Dir.glob(base_path).each do |f|
        next unless File.file?(f)
        objects.push cloud[relative_path_for(f)]
      end
      objects
    end

    def read(key)
      File.read(path_for(key))
    rescue Errno::ENOENT => e
      raise AssetCloud::AssetNotFoundError, key
    end

    def delete(key)
      File.delete(path_for(key))
    rescue Errno::ENOENT
    end

    def write(key, data)
      execute_in_full_path(key) do |path|
        File.open(path, "wb+") { |fp| fp << data }
        true
      end
    end

    def stat(key)
      begin
        stat = File.stat(path_for(key))
        Metadata.new(true, stat.size, stat.ctime, stat.mtime)
      rescue Errno::ENOENT => e
        Metadata.new(false)
      end
    end

    protected

    def path_for(key)
      cloud.path_for(key)
    end

    def path
      cloud.path
    end

    private

    def remove_full_path_regexp
      @regexp ||= /^#{path}\//
    end

    def relative_path_for(f)
      f.sub(remove_full_path_regexp, '')
    end

    def execute_in_full_path(key, &block)
      path = path_for(key)

      find_or_create_and_execute(path, &block)
    end

    def find_or_create_and_execute(path)
      retried = false

      begin
        yield(path)
      rescue Errno::ENOENT => e
        raise if retried

        directory = File.dirname(path)
        FileUtils.mkdir_p(File.dirname(path))
        retried = true
        retry
      end
    end
  end
end
