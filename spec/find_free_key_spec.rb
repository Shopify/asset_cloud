
require 'spec_helper'


class FindFreeKey
  extend AssetCloud::FreeKeyLocator
end

describe "FreeFilenameLocator", 'when asked to return a free key such as the one passed in' do

  it "should simply return the key if it happens to be free" do
    FindFreeKey.should_receive(:exist?).with('free.txt').and_return(false)

    FindFreeKey.find_free_key_like('free.txt').should == 'free.txt'
  end

  it "should append a UUID to the key before the extension if key is taken" do
    SecureRandom.stub(:uuid).and_return('moo')
    FindFreeKey.should_receive(:exist?).with('free.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_moo.txt').and_return(false)

    FindFreeKey.find_free_key_like('free.txt').should == 'free_moo.txt'
  end


  it "should not strip any directory information from the key" do
    SecureRandom.stub(:uuid).and_return('moo')
    FindFreeKey.should_receive(:exist?).with('products/images/image.gif').and_return(true)
    FindFreeKey.should_receive(:exist?).with('products/images/image_moo.gif').and_return(false)

    FindFreeKey.find_free_key_like('products/images/image.gif').should == 'products/images/image_moo.gif'
  end

  it "should raise an exception if the randomly chosen value (after 10 attempts) is also taken" do
    FindFreeKey.stub(:exist?).and_return(true)
    lambda { FindFreeKey.find_free_key_like('free.txt') }.should raise_error(StandardError)
  end

  it "should append a UUID to the key before the extensions if the force_uuid option is passed" do
    FindFreeKey.should_receive(:exist?).with('free.txt').and_return(false)
    FindFreeKey.should_receive(:exist?).with('free_as-in-beer.txt').and_return(false)
    SecureRandom.stub(:uuid).and_return('as-in-beer')

    FindFreeKey.find_free_key_like('free.txt', :force_uuid => true).should == 'free_as-in-beer.txt'
  end
end
