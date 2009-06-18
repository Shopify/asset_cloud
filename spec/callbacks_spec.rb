require File.dirname(__FILE__) + '/spec_helper'

class CallbackAsset < AssetCloud::Asset
  before_store :callback_before_store
  after_delete :callback_after_delete
end

class BasicCloud < AssetCloud::Base
  bucket :callback_assets, AssetCloud::MemoryBucket, :asset_class => CallbackAsset
end

class CallbackCloud < AssetCloud::Base
  bucket :tmp, AssetCloud::MemoryBucket
  
  after_delete :callback_after_delete
  before_delete :callback_before_delete
   
  after_write :callback_after_write
  before_write :callback_before_write
end

class MethodRecordingCloud < AssetCloud::Base
  attr_accessor :run_callbacks
  
  bucket :tmp, AssetCloud::MemoryBucket  

  before_write :callback_before_write
  after_write :callback_before_write


  def method_missing(method, *args)
    @run_callbacks << method.to_sym
  end
end

describe CallbackCloud do
  before { @fs = CallbackCloud.new(File.dirname(__FILE__) + '/files', 'http://assets/') }
  
  it "should invoke callbacks after store" do
    
    @fs.should_receive(:callback_before_write).with('tmp/file.txt', 'text').and_return(true)
    @fs.should_receive(:callback_after_write).with('tmp/file.txt', 'text').and_return(true)
    
    
    @fs.write 'tmp/file.txt', 'text'
    
  end

  it "should invoke callbacks after delete" do
    
    @fs.should_receive(:callback_before_delete).with('tmp/file.txt').and_return(true)
    @fs.should_receive(:callback_after_delete).with('tmp/file.txt').and_return(true)
    
    
    @fs.delete 'tmp/file.txt'    
  end                        
  
  it "should invoke callbacks even when constructing a new asset" do
    @fs.should_receive(:callback_before_write).with('tmp/file.txt', 'hello').and_return(true)
    @fs.should_receive(:callback_after_write).with('tmp/file.txt', 'hello').and_return(true)
    
    
    asset = @fs.build('tmp/file.txt')
    asset.value = 'hello'
    asset.store
    
  end
  
end

describe MethodRecordingCloud do
  before do 
    @fs = MethodRecordingCloud.new(File.dirname(__FILE__) + '/files', 'http://assets/') 
    @fs.run_callbacks = []
  end
   
  it 'should record event when invoked' do
    @fs.write('tmp/file.txt', 'random data')        
    @fs.run_callbacks.should == [:callback_before_write, :callback_before_write]
  end

  it 'should record event when assignment operator is used' do
    @fs['tmp/file.txt'] = 'random data'
    @fs.run_callbacks.should == [:callback_before_write, :callback_before_write]
  end
end

describe CallbackAsset do
  before(:each) do
    @fs = BasicCloud.new(File.dirname(__FILE__) + '/files', 'http://assets/')
    @fs.write('callback_assets/foo', 'bar')
    @asset = @fs.asset_at('callback_assets/foo')
  end
  
  it "should run its before_store callback before store is called" do
    @asset.should_receive(:callback_before_store).and_return(true)
    @asset.should_not_receive(:callback_after_delete)
    
    @asset.store
  end
  
  it "should run its after_delete callback after delete is called" do
    @asset.should_not_receive(:callback_before_store)
    @asset.should_receive(:callback_after_delete).and_return(true)
    
    @asset.delete
  end
end