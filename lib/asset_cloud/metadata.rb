module AssetCloud
  class Metadata
    attr_accessor :exist, :size, :created_at, :updated_at, :value_hash, :checksum

    def new?
      !self.exist
    end

    def exist?
      self.exist
    end

    # rubocop:disable Metrics/ParameterLists
    def initialize(exist, size = nil, created_at = nil, updated_at = nil, value_hash = nil, checksum = nil)
      self.exist = exist
      self.size = size
      self.created_at = created_at
      self.updated_at = updated_at
      self.value_hash = value_hash
      self.checksum = checksum
    end
    # rubocop:enable Metrics/ParameterLists

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
