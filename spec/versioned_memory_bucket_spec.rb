# frozen_string_literal: true

require "spec_helper"

class VersionedMemoryCloud < AssetCloud::Base
  bucket :memory, AssetCloud::VersionedMemoryBucket
end

describe AssetCloud::VersionedMemoryBucket do
  directory = File.dirname(__FILE__) + "/files"

  before do
    @fs = VersionedMemoryCloud.new(directory, "http://assets/files")
    ["one", "two", "three"].each do |content|
      @fs.write("memory/foo", content)
    end
  end

  describe "#versioned?" do
    it "should return true" do
      expect(@fs.buckets[:memory].versioned?).to(eq(true))
    end
  end

  describe "#read_version" do
    it "should return the appropriate data when given a key and version" do
      expect(@fs.read_version("memory/foo", 1)).to(eq("one"))
      expect(@fs.read_version("memory/foo", 3)).to(eq("three"))
    end
  end

  describe "#versions" do
    it "should return a list of available version identifiers for the given key" do
      expect(@fs.versions("memory/foo")).to(eq([1, 2, 3]))
    end
  end
end
