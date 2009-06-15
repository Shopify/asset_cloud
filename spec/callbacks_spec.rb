require File.dirname(__FILE__) + '/spec_helper'

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