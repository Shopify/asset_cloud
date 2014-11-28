require 'spec_helper'

class ValidatedAsset < AssetCloud::Asset
  validate :no_cats

  private
  def no_cats
    add_error('no cats allowed!') if value =~ /cat/i
    add_warning('bad dog!', 'wet dog smell!') if value =~ /dog/i
  end
end

class BasicCloud < AssetCloud::Base
  bucket :dog_pound, AssetCloud::MemoryBucket, :asset_class => ValidatedAsset
end

describe ValidatedAsset do
  before(:each) do
    @cloud = BasicCloud.new(File.dirname(__FILE__) + '/files', 'http://assets/')
    @cat = @cloud.build('dog_pound/fido', 'cat')
    @dog = @cloud.build('dog_pound/fido', 'dog')
  end

  describe "#store" do
    it "should not store the asset unless validations pass" do
      @cloud.should_receive(:write).with('dog_pound/fido', 'dog').and_return(true)

      @cat.store
      @cat.store.should == false
      @cat.errors.should == ['no cats allowed!']
      @dog.store.should == true
    end

    it "should store asset with warnings and save them in the warnings array" do
      @dog.store.should == true
      @dog.warnings.should == ['bad dog!', 'wet dog smell!']
      @cat.store.should == false
      @cat.warnings.should == []
    end
  end

  describe "#io" do
    it "should not create an io asset unless validations pass" do

      @cat.io.should == false
      @cat.errors.should == ['no cats allowed!']
      @dog.io.should be_an_instance_of AssetCloud::MemoryBucketIO
    end

    it "should retrieve an io with warnings and save them in the warnings array" do
      @dog.io.should be_an_instance_of AssetCloud::MemoryBucketIO
      @dog.warnings.should == ['bad dog!', 'wet dog smell!']
      @cat.io.should == false
      @cat.warnings.should == []
    end
  end

  describe "#valid?" do
    it "should clear errors, run validations, and return validity" do
      @cat.store
      @cat.errors.should == ['no cats allowed!']
      @cat.valid?.should == false
      @cat.errors.should == ['no cats allowed!']
      @cat.value = 'disguised feline'
      @cat.valid?.should == true
      @cat.errors.should be_empty
    end
  end
end
