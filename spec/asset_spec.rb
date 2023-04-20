# frozen_string_literal: true

require "spec_helper"

describe "Asset" do
  include AssetCloud

  before do
    @cloud = double("Cloud", asset_extension_classes_for_bucket: [])
  end

  describe "when first created (without a value)" do
    before do
      @asset = AssetCloud::Asset.new(@cloud, "products/key.txt")
    end

    it "should be return new_asset? => true" do
      expect(@asset.new_asset?).to(eq(true))
    end

    it "should have a key" do
      expect(@asset.key).to(eq("products/key.txt"))
    end

    it "should have a value of nil" do
      expect(@asset.value).to(eq(nil))
    end

    it "should have a basename" do
      expect(@asset.basename).to(eq("key.txt"))
    end

    it "should have a basename without ext (if required)" do
      expect(@asset.basename_without_ext).to(eq("key"))
    end

    it "should have an ext" do
      expect(@asset.extname).to(eq(".txt"))
    end

    it "should have a relative_key_without_ext" do
      expect(@asset.relative_key_without_ext).to(eq("key"))
    end

    it "should have a bucket_name" do
      expect(@asset.bucket_name).to(eq("products"))
    end

    it "should have a bucket" do
      expect(@cloud).to(receive(:buckets).and_return(products: :products_bucket))
      expect(@asset.bucket).to(eq(:products_bucket))
    end

    it "should store data to the bucket" do
      expect(@cloud).to(receive(:write).with("products/key.txt", "value"))

      @asset.value = "value"
      @asset.store
    end

    it "should not try to store data when it's value is nil" do
      expect(@cloud).to(receive(:write).never)

      @asset.store
    end

    it "should not try to read data from bucket if its a new_asset" do
      expect(@cloud).to(receive(:read).never)

      expect(@asset.value).to(eq(nil))
    end

    it "should simply ignore calls to delete" do
      expect(@cloud).to(receive(:delete).never)

      @asset.delete
    end
  end

  describe "when first created (without a value) with subdirectory" do
    before do
      @asset = AssetCloud::Asset.new(@cloud, "products/retail/key.txt")
    end

    it "should have a relative_key_without_ext" do
      expect(@asset.relative_key_without_ext).to(eq("retail/key"))
    end

    it "should have a relative_key" do
      expect(@asset.relative_key).to(eq("retail/key.txt"))
    end
  end

  describe "when first created with value" do
    before do
      @asset = AssetCloud::Asset.new(@cloud, "products/key.txt", "value")
    end

    it "should be return new_asset? => true" do
      expect(@asset.new_asset?).to(eq(true))
    end

    it "should have a value of 'value'" do
      expect(@asset.value).to(eq("value"))
    end

    it "should return false when asked if it exists because its still a new_asset" do
      expect(@asset.exist?).to(eq(false))
    end

    it "should not try to read data from bucket if its a new_asset" do
      expect(@cloud).to(receive(:read).never)

      expect(@asset.value).to(eq("value"))
    end

    it "should write data to the bucket" do
      expect(@cloud).to(receive(:write).with("products/key.txt", "value"))
      @asset.store
    end
  end

  describe "when fetched from the bucket" do
    before do
      @asset = AssetCloud::Asset.at(
        @cloud,
        "products/key.txt",
        "value",
        AssetCloud::Metadata.new(true, "value".size, Time.now, Time.now),
      )
    end

    it "should be return new_asset? => false" do
      expect(@asset.new_asset?).to(eq(false))
    end

    it "should indicate that it exists" do
      expect(@asset.exist?).to(eq(true))
    end

    it "should read the value from the bucket" do
      expect(@asset.value).to(eq("value"))
    end

    it "should simply ignore calls to delete" do
      expect(@cloud).to(receive(:delete).and_return(true))

      @asset.delete
    end

    it "should ask the bucket to create a full url" do
      expect(@cloud).to(receive(:url_for).with("products/key.txt", {}).and_return("http://assets/products/key.txt"))

      expect(@asset.url).to(eq("http://assets/products/key.txt"))
    end

    it "should ask the bucket whether or not it is versioned" do
      bucket = double("Bucket")
      expect(@cloud).to(receive(:buckets).and_return(products: bucket))
      expect(bucket).to(receive(:versioned?).and_return(true))

      expect(@asset.versioned?).to(eq(true))
    end

    it "should validate its key" do
      asset = AssetCloud::Asset.new(@cloud, "products/foo, bar.txt", "data")
      expect(asset.store).to(eq(false))
      expect(asset.errors.size).to(eq(1))
      expect(asset.errors.first).to(match(/illegal characters/))
    end
  end

  describe "comparable" do
    before do
      @key = "products/key.txt"
      @asset = AssetCloud::Asset.new(@cloud, @key)
    end

    context "comparing to instance of Asset class" do
      it "is equal if cloud and key of both assets are equal" do
        other_asset = AssetCloud::Asset.new(@cloud, @key)

        expect(@asset == other_asset).to(eq(true))
      end

      it "is not equal if key of both assets are not equal" do
        other_key = "products/other_key.txt"
        other_asset = AssetCloud::Asset.new(@cloud, other_key)

        expect(@asset == other_asset).to(eq(false))
      end
    end

    context "comparing to instance of non-Asset class" do
      it "is not equal to a non-Asset object" do
        AssetCloud::Asset.new(@cloud, "products/foo, bar.txt", "data")

        expect(@asset == "some_string").to(eq(false))
        expect(@asset == :some_symbol).to(eq(false))
        expect(@asset == []).to(eq(false))
        expect(@asset.nil?).to(eq(false))

        expect(@asset <=> "some_string").to(eq(nil))
        expect(@asset <=> :some_symbol).to(eq(nil))
        expect(@asset <=> []).to(eq(nil))
        expect(@asset <=> nil).to(eq(nil))
      end
    end
  end
end
