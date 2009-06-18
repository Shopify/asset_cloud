require File.dirname(__FILE__) + '/spec_helper'

class ValidatedAsset < AssetCloud::Asset
  validate :no_cats
  
  private
  def no_cats
    add_error('no cats allowed!') if value =~ /cat/i
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