# frozen_string_literal: true

require "spec_helper"

class MemoryCloud < AssetCloud::Base
  bucket :memory, AssetCloud::MemoryBucket
end

describe AssetCloud::MemoryBucket do
  directory = File.dirname(__FILE__) + "/files"

  before do
    @fs = MemoryCloud.new(directory, "http://assets/files")
  end

  describe "modifying items in subfolder" do
    it "should return nil when file does not exist" do
      expect(@fs["memory/essay.txt"].exist?).to(eq(false))
    end

    it "should return set content when asked for the same file" do
      @fs["memory/essay.txt"] = "text"
      expect(@fs["memory/essay.txt"].value).to(eq("text"))
    end
  end

  describe "#versioned?" do
    it "should return false" do
      expect(@fs.buckets[:memory].versioned?).to(eq(false))
    end
  end

  describe "#ls" do
    before do
      ["a", "b"].each do |letter|
        2.times { |number| @fs.write("memory/#{letter}#{number}", ".") }
      end
    end

    it "should return a list of assets which start with the given prefix" do
      expect(@fs.buckets[:memory].ls("memory/a").size).to(eq(2))
    end

    it "should return a list of all assets when a prefix is not given" do
      expect(@fs.buckets[:memory].ls.size).to(eq(4))
    end
  end
end
