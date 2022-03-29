# frozen_string_literal: true

require "spec_helper"

class BlackholeCloud < AssetCloud::Base
  bucket AssetCloud::BlackholeBucket
end

describe BlackholeCloud do
  directory = File.dirname(__FILE__) + "/files"

  before do
    @fs = BlackholeCloud.new(directory, "http://assets/files")
  end

  it "should allow access to files using the [] operator" do
    @fs["tmp/image.jpg"]
  end

  it "should return nil for non existent files" do
    expect(@fs["tmp/image.jpg"].exist?).to(eq(false))
  end

  it "should still return nil, even if you wrote something there" do
    @fs["tmp/image.jpg"] = "test"
    expect(@fs["tmp/image.jpg"].exist?).to(eq(false))
  end

  describe "when using a sub path" do
    it "should allow access to files using the [] operator" do
      @fs["tmp/image.jpg"]
    end

    it "should return nil for non existent files" do
      expect(@fs["tmp/image.jpg"].exist?).to(eq(false))
    end

    it "should still return nil, even if you wrote something there" do
      @fs["tmp/image.jpg"] = "test"
      expect(@fs["tmp/image.jpg"].exist?).to(eq(false))
    end
  end
end
