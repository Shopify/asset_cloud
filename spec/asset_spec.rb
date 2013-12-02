require 'spec_helper'

describe "Asset" do
  include AssetCloud

  before do
    @cloud = double('Cloud', :asset_extension_classes_for_bucket => [])
  end

  describe "when first created (without a value)" do
    before do
      @asset = AssetCloud::Asset.new(@cloud, "products/key.txt")
    end

    it "should be return new_asset? => true" do
      @asset.new_asset?.should == true
    end

    it "should have a key" do
      @asset.key.should == 'products/key.txt'
    end

    it "should have a value of nil" do

      @asset.value.should == nil
    end

    it "should have a basename" do
      @asset.basename.should == 'key.txt'
    end

    it "should have a basename without ext (if required)" do
      @asset.basename_without_ext.should == 'key'
    end

    it "should have an ext" do
      @asset.extname.should == '.txt'
    end

    it "should have a relative_key_without_ext" do
      @asset.relative_key_without_ext.should == 'key'
    end

    it "should have a bucket_name" do
      @asset.bucket_name.should == 'products'
    end

    it "should have a bucket" do
      @cloud.should_receive(:buckets).and_return(:products => :products_bucket)
      @asset.bucket.should == :products_bucket
    end

    it "should store data to the bucket" do
      @cloud.should_receive(:write).with("products/key.txt", 'value')

      @asset.value = 'value'
      @asset.store
    end

    it "should not try to store data when it's value is nil" do
      @cloud.should_receive(:write).never

      @asset.store
    end

    it "should not try to read data from bucket if its a new_asset" do
      @cloud.should_receive(:read).never

      @asset.value.should == nil
    end

    it "should simply ignore calls to delete" do
      @cloud.should_receive(:delete).never

      @asset.delete
    end

  end


  describe "when first created (without a value) with subdirectory" do
    before do
      @asset = AssetCloud::Asset.new(@cloud, "products/retail/key.txt")
    end

    it "should have a relative_key_without_ext" do
      @asset.relative_key_without_ext.should == 'retail/key'
    end

    it "should have a relative_key" do
      @asset.relative_key.should == 'retail/key.txt'
    end
  end


  describe "when first created with value" do
    before do
      @asset = AssetCloud::Asset.new(@cloud, "products/key.txt", 'value')
    end

    it "should be return new_asset? => true" do
      @asset.new_asset?.should == true
    end


    it "should have a value of 'value'" do
      @asset.value.should == 'value'
    end

    it "should return false when asked if it exists because its still a new_asset" do
      @asset.exist?.should == false
    end


    it "should not try to read data from bucket if its a new_asset" do
      @cloud.should_receive(:read).never

      @asset.value.should == 'value'
    end

    it "should write data to the bucket" do
      @cloud.should_receive(:write).with("products/key.txt", 'value')
      @asset.store
    end

  end

  describe "when fetched from the bucket" do
    before do
      @asset = AssetCloud::Asset.at(@cloud, "products/key.txt", 'value', AssetCloud::Metadata.new(true, 'value'.size, Time.now, Time.now))
    end

    it "should be return new_asset? => false" do
      @asset.new_asset?.should == false
    end

    it "should indicate that it exists" do

      @asset.exist?.should == true
    end


    it "should read the value from the bucket" do
      @asset.value.should == 'value'
    end


    it "should simply ignore calls to delete" do
      @cloud.should_receive(:delete).and_return(true)

      @asset.delete
    end

    it "should ask the bucket to create a full url" do
      @cloud.should_receive(:url_for).with('products/key.txt', {}).and_return('http://assets/products/key.txt')

      @asset.url.should == 'http://assets/products/key.txt'
    end

    it "should ask the bucket whether or not it is versioned" do
      bucket = double('Bucket')
      @cloud.should_receive(:buckets).and_return(:products => bucket)
      bucket.should_receive(:versioned?).and_return(true)

      @asset.versioned?.should == true
    end

    it "should validate its key" do
      asset = AssetCloud::Asset.new(@cloud, "products/foo, bar.txt", "data")
      asset.store.should == false
      asset.errors.size.should == 1
      asset.errors.first.should =~ /illegal characters/
    end
  end


end
