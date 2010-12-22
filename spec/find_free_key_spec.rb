 
require File.dirname(__FILE__) + '/spec_helper'


class FindFreeKey
  extend AssetCloud::FreeKeyLocator
end                                      

describe "FreeFilenameLocator", 'when asked to return a free key such as the one passed in' do
    
  it "should simply return the key if it happens to be free" do
    FindFreeKey.should_receive(:exist?).with('free.txt').and_return(false)

    FindFreeKey.find_free_key_like('free.txt').should == 'free.txt'
  end           
  
  it "should append _1 to the key before the extension if key is taken " do                      
    FindFreeKey.should_receive(:exist?).with('free.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_1.txt').and_return(false)
    
    FindFreeKey.find_free_key_like('free.txt').should == 'free_1.txt'
  end
                                                               
  
  it "should should increment the number at the end of the basename until it finds a free filename" do
    FindFreeKey.should_receive(:exist?).with('free.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_1.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_2.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_3.txt').and_return(false)
    
    FindFreeKey.find_free_key_like('free.txt').should == 'free_3.txt'    
  end                                                                                              
  
  it "should recognize a number at the end of the filename and simply increment that one" do
    FindFreeKey.should_receive(:exist?).with('file9.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('file10.txt').and_return(false)
    
    FindFreeKey.find_free_key_like('file9.txt').should == 'file10.txt' 
  end                                         
  
   
  it "should not strip any directory information from the key" do
    FindFreeKey.should_receive(:exist?).with('products/images/image.gif').and_return(true)
    FindFreeKey.should_receive(:exist?).with('products/images/image_1.gif').and_return(true)
    FindFreeKey.should_receive(:exist?).with('products/images/image_2.gif').and_return(false)
    
    FindFreeKey.find_free_key_like('products/images/image.gif').should == 'products/images/image_2.gif' 
  end
  
  it "should just pick a random value after 10 sequential attempts" do
    FindFreeKey.should_receive(:exist?).with('free.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_1.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_2.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_3.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_4.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_5.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_6.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_7.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_8.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_9.txt').and_return(true)
    FindFreeKey.should_receive(:exist?).with('free_10.txt').and_return(true)
                             
    lambda { FindFreeKey.find_free_key_like('free.txt').should == 'file10.txt' }.should raise_error(RSpec::Mocks::MockExpectationError)
  end
    
end