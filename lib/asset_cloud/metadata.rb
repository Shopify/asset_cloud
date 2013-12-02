module AssetCloud
  class Metadata
    attr_accessor :exist, :size, :created_at, :updated_at, :value_hash

    def new?
      !self.exist
    end

    def exist?
      self.exist
    end

    def initialize(exist, size = nil, created_at = nil, updated_at = nil, value_hash = nil)
      self.exist, self.size, self.created_at, self.updated_at, self.value_hash = exist, size, created_at, updated_at, value_hash
    end

    def self.existing
      self.new(true)
    end

    def self.non_existing
      self.new false
    end

    def inspect
      "#<#{self.class.name}: exist:#{exist} size:#{size.inspect} bytes>"
    end
  end
end
