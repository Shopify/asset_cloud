# frozen_string_literal: true

module AssetCloud
  class Metadata
    attr_accessor :exist, :size, :created_at, :updated_at, :value_hash, :checksum

    def new?
      !exist
    end

    def exist?
      exist
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

    class << self
      def existing
        new(true)
      end

      def non_existing
        new(false)
      end
    end

    def inspect
      "#<#{self.class.name}: exist:#{exist} size:#{size.inspect} bytes>"
    end
  end
end
