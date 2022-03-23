# frozen_string_literal: true

require "spec_helper"
require "asset_cloud/metadata"

module AssetCloud
  describe Metadata do
    it "exposes the checksum" do
      exist = true
      size = 1
      created_at = Time.utc(2020, 5, 19, 13, 14, 15)
      updated_at = Time.utc(2020, 5, 19, 16, 17, 18)
      value_hash = "abc123"
      checksum = "def456"

      metadata = Metadata.new(exist, size, created_at, updated_at, value_hash, checksum)

      expect(metadata.checksum).to(eq("def456"))
    end

    it "defaults the checksum to nil if not provided" do
      exist = true
      size = 1
      created_at = Time.utc(2020, 5, 19, 13, 14, 15)
      updated_at = Time.utc(2020, 5, 19, 16, 17, 18)
      value_hash = "abc123"

      metadata = Metadata.new(exist, size, created_at, updated_at, value_hash)

      expect(metadata.checksum).to(be(nil))
    end
  end
end
