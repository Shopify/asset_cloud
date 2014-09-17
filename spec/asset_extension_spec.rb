require 'spec_helper'

class NoCatsAsset < AssetCloud::Asset
  validate :no_cats
  before_store :asset_callback

  private
  def no_cats
    add_error('no cats allowed!') if value =~ /cat/i
  end
end

class CssAssetExtension < AssetCloud::AssetExtension
  applies_to :css

  validate :valid_css

  private
  def valid_css
    add_error "not enough curly brackets!" unless asset.value =~ /\{.*\}/
  end
end

class XmlAssetExtension < AssetCloud::AssetExtension
  applies_to :xml

  validate :valid_xml
  before_store :xml_callback

  def turn_into_xml
    asset.value = "<xml>#{asset.value}</xml>"
  end

  private
  def valid_xml
    add_error "not enough angle brackets!" unless asset.value =~ /\<.*\>/
  end
end

class CatsAndDogsCloud < AssetCloud::Base
  bucket :dog_pound, AssetCloud::MemoryBucket, :asset_class => NoCatsAsset
  bucket :cat_pen, AssetCloud::MemoryBucket

  asset_extensions CssAssetExtension, :only => :cat_pen
  asset_extensions XmlAssetExtension, :except => :cat_pen
end

describe "AssetExtension" do
  include AssetCloud

  before do
    @cloud = CatsAndDogsCloud.new(File.dirname(__FILE__) + '/files', 'http://assets/')
  end

  describe "applicability" do
    it "should work" do
      asset = @cloud['cat_pen/cats.xml']
      XmlAssetExtension.applies_to_asset?(asset).should == true
    end
  end

  describe "validations" do
    it "should be added to assets in the right bucket with the right extension" do
      asset = @cloud['cat_pen/cats.css']
      asset.value = 'foo'
      asset.store.should == false
      asset.errors.should == ["not enough curly brackets!"]
    end

    it "should not squash existing validations on the asset" do
      asset = @cloud['dog_pound/cats.xml']
      asset.value = 'cats!'
      asset.store.should == false
      asset.errors.should == ['no cats allowed!', "not enough angle brackets!"]
    end

    it "should not apply to non-matching assets or those in exempted buckets" do
      asset = @cloud['cat_pen/cats.xml']
      asset.value = "xml"
      asset.store.should == true
    end
  end

  describe "callbacks" do
    it "should run alongside the asset's callbacks" do
      asset = @cloud['dog_pound/dogs.xml']
      asset.should_receive(:asset_callback)
      asset.extensions.first.should_receive(:xml_callback)
      asset.value = '<dogs/>'
      asset.store.should == true
    end
  end

  describe "#method_missing" do
    it "should try to run method on extensions" do
      asset = @cloud['dog_pound/dogs.xml']
      asset.value = 'dogs'
      asset.turn_into_xml
      asset.value.should == '<xml>dogs</xml>'
    end

    it "does not swallow NotImplementedError" do
      XmlAssetExtension.send(:define_method, :my_unimplemented_extension) do
        raise NotImplementedError
      end

      asset = @cloud['dog_pound/dogs.xml']

      expect(asset).to respond_to(:my_unimplemented_extension)
      expect { asset.my_unimplemented_extension }.to raise_error(NotImplementedError)
    end
  end

end
