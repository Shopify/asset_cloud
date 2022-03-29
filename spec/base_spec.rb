# frozen_string_literal: true

require "spec_helper"

class SpecialAsset < AssetCloud::Asset
end

class LiquidAsset < AssetCloud::Asset
end

class BrokenBucket < AssetCloud::Bucket
  def write(*)
    false
  end
end

class BasicCloud < AssetCloud::Base
  bucket :special, AssetCloud::MemoryBucket, asset_class: SpecialAsset
  bucket :conditional, AssetCloud::MemoryBucket, asset_class: proc { |key|
    LiquidAsset if key.ends_with?(".liquid")
  }
  bucket :broken, BrokenBucket, asset_class: AssetCloud::Asset
end

describe BasicCloud do
  directory = File.dirname(__FILE__) + "/files"

  before do
    @fs = BasicCloud.new(directory, "http://assets/files")
  end

  it "should raise invalid bucket if none is given" do
    expect(@fs["image.jpg"].exist?).to(eq(false))
  end

  it "should be backed by a file system bucket" do
    expect(@fs["products/key.txt"].exist?).to(eq(true))
  end

  it "should raise when listing non existing buckets" do
    expect(@fs.ls("products")).to(eq([AssetCloud::Asset.new(@fs, "products/key.txt")]))
  end

  it "should allow you to create new assets" do
    obj = @fs.build("new_file.test")
    expect(obj).to(be_an_instance_of(AssetCloud::Asset))
    expect(obj.cloud).to(be_an_instance_of(BasicCloud))
  end

  it "should raise error when using with minus relative or absolute paths" do
    expect { @fs["../test"]  }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["/test"]    }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs[".../test"] }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["./test"]   }.to(raise_error(AssetCloud::IllegalPath))
  end

  it "should raise error when filename has trailing period" do
    expect { @fs["test."]             }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["/test/testfile."]   }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["test/directory/."]  }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["/test/testfile ."]  }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["test/directory /."] }.to(raise_error(AssetCloud::IllegalPath))
  end

  it "should raise error when filename ends with space" do
    expect { @fs["test "]             }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["/test/testfile "]   }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["test/directory/ "]  }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["test. "]            }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["/test/testfile. "]  }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["test/directory/. "] }.to(raise_error(AssetCloud::IllegalPath))
  end

  it "should raise error when filename ends with slash" do
    expect { @fs["test/"]             }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["test/directory/"]   }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["test /"]            }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["/test/testfile /"]  }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["test/directory//"]  }.to(raise_error(AssetCloud::IllegalPath))
  end

  it "should raise error when using with minus relative even after another directory" do
    expect { @fs["test/../test"]      }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["test/../../test"]   }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["test/../../../test"] }.to(raise_error(AssetCloud::IllegalPath))
  end

  it "should raise an error when using names with combinations of '.' and ' '" do
    expect { @fs["test. . . .. ... .. . "]   }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["test. ."] }.to(raise_error(AssetCloud::IllegalPath))
    expect { @fs["test.   .test2"] }.to(raise_error(AssetCloud::IllegalPath))
  end

  it "should allow filenames with repeating dots" do
    @fs["test..jpg"]
    @fs["assets/T.T..jpg"]
    @fs["test/assets/1234123412341234_obj_description..14...58......v8...._2134123412341234.jpg"]
  end

  it "should allow filenames with repeating underscores" do
    @fs["test__jpg"]
    @fs["assets/T__T..jpg"]
    @fs["test/assets/1234123412341234_obj_description..14...58......v8...__2134123412341234.jpg"]
  end

  it "should allow filenames with various bracket arragements" do
    @fs["test[1].jpg"]
    @fs["test[1]"]
    @fs["[test].jpg"]
  end

  it "should not raise an error when using directory names with spaces" do
    @fs["files/ass ets/.DS_Store"]
  end

  it "should not raise_error when using unusual but valid filenames" do
    @fs[".DS_Store"]
    @fs["photograph.g"]
    @fs["_testfilename"]
    @fs["assets/.DS_Store"]
    @fs["assets/photograph.g"]
    @fs["a/_testfilename"]
    @fs["a"]
  end

  it "should allow sensible relative filenames" do
    @fs["assets/rails_logo.gif"]
    @fs["assets/rails_logo"]
    @fs["assets/rails-2.gif"]
    @fs["assets/223434.gif"]
    @fs["files/1.JPG"]
  end

  it "should compute complete urls to assets" do
    expect(@fs.url_for("products/[key] with spaces.txt?foo=1&bar=2")).to(eq("http://assets/files/products/[key]%20with%20spaces.txt?foo=1&bar=2"))
  end

  describe "#find" do
    it "should return the appropriate asset when one exists" do
      asset = @fs.find("products/key.txt")
      expect(asset.key).to(eq("products/key.txt"))
      expect(asset.value).to(eq("value"))
    end
    it "should raise AssetNotFoundError when the asset doesn't exist" do
      expect { @fs.find("products/not-there.txt") }.to(raise_error(AssetCloud::AssetNotFoundError))
    end
  end

  describe "#[]" do
    it "should return the appropriate asset when one exists" do
      asset = @fs["products/key.txt"]
      expect(asset.key).to(eq("products/key.txt"))
      expect(asset.value).to(eq("value"))
    end
    it "should not raise any errors when the asset doesn't exist" do
      expect { @fs["products/not-there.txt"] }.not_to(raise_error)
    end
  end

  describe "#move" do
    it "should return move a resource" do
      asset = @fs["products/key.txt"]
      expect(asset.key).to(eq("products/key.txt"))
      expect(asset.value).to(eq("value"))
      @fs.move("products/key.txt", "products/key2.txt")
      new_asset = @fs["products/key2.txt"]
      expect(new_asset.key).to(eq("products/key2.txt"))
      expect(new_asset.value).to(eq("value"))
      expect { @fs["products/key.txt"].value }.to(raise_error(AssetCloud::AssetNotFoundError))
      @fs.move("products/key2.txt", "products/key.txt")
    end
  end

  describe "#[]=" do
    it "should write through the Asset object (and thus run any callbacks on the asset)" do
      special_asset = double(:special_asset)
      expect(special_asset).to(receive(:value=).with("fancy fancy!"))
      expect(special_asset).to(receive(:store))
      expect(SpecialAsset).to(receive(:at).and_return(special_asset))
      @fs["special/fancy.txt"] = "fancy fancy!"
    end
  end

  describe "#bucket" do
    it "should allow specifying a class to use for assets in this bucket" do
      expect(@fs["assets/rails_logo.gif"]).to(be_instance_of(AssetCloud::Asset))
      expect(@fs["special/fancy.txt"]).to(be_instance_of(SpecialAsset))

      expect(@fs.build("assets/foo")).to(be_instance_of(AssetCloud::Asset))
      expect(@fs.build("special/foo")).to(be_instance_of(SpecialAsset))
    end

    it "should allow specifying a proc that determines the class to use, using the default bucket when returning nil" do
      expect(@fs.build("conditional/default.js")).to(be_instance_of(AssetCloud::Asset))
      expect(@fs.build("conditional/better.liquid")).to(be_instance_of(LiquidAsset))
    end

    it "should raise " do
      expect { BasicCloud.bucket(AssetCloud::MemoryBucket, asset_class: proc {}) }.to(raise_error(ArgumentError))
    end
  end

  describe "write!" do
    it "should write through the Asset object (and thus run any callbacks on the asset)" do
      special_asset = double(:special_asset)
      expect(special_asset).to(receive(:value=).with("fancy fancy!"))
      expect(special_asset).to(receive(:store!))
      expect(SpecialAsset).to(receive(:at).and_return(special_asset))
      @fs.write!("special/fancy.txt", "fancy fancy!")
    end

    it "should raise AssetNotSaved when write fails" do
      expect { @fs.write!("broken/file.txt", "n/a") }.to(raise_error(AssetCloud::AssetNotSaved))
    end
  end

  describe "MATCH_BUCKET" do
    it "should match following stuff " do
      "products/key.txt" =~ AssetCloud::Base::MATCH_BUCKET
      expect(Regexp.last_match(1)).to(eq("products"))

      "products/subpath/key.txt" =~ AssetCloud::Base::MATCH_BUCKET
      expect(Regexp.last_match(1)).to(eq("products"))

      "key.txt" =~ AssetCloud::Base::MATCH_BUCKET
      expect(Regexp.last_match(1)).to(eq(nil))

      "products" =~ AssetCloud::Base::MATCH_BUCKET
      expect(Regexp.last_match(1)).to(eq("products"))
    end
  end
end
