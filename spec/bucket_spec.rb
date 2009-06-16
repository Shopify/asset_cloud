require File.dirname(__FILE__) + '/spec_helper'

class ChainedCloud < AssetCloud::Base
  bucket :stuff, AssetCloud::Bucket.chain(AssetCloud::MemoryBucket, AssetCloud::BlackholeBucket)
end

describe AssetCloud::Bucket do    
  directory = File.dirname(__FILE__) + '/files'
  
  before(:each) do
    @cloud = ChainedCloud.new(directory , 'http://assets/files' )
    @bucket_chain = @cloud.buckets[:stuff]
    @memory_bucket, @blackhole_bucket = @bucket_chain.chained_buckets
  end
  
  describe "#chain" do
    it 'should take multiple Bucket classes and return a new Bucket class' do
      @bucket_chain.should be_a_kind_of(AssetCloud::Bucket)
    end
    
    it 'should return a Bucket which writes to each sub-bucket' do
      @bucket_chain.chained_buckets.each do |bucket|
        bucket.should_receive(:write).with('stuff/foo', 'bar').and_return(true)
        bucket.should_receive(:delete).with('stuff/foo').and_return(true)
      end
      
      @bucket_chain.write('stuff/foo', 'bar')
      @bucket_chain.delete('stuff/foo')
    end
    
    it 'should return a Bucket which reads from only the first sub-bucket' do
      @memory_bucket.should_receive(:read).with('stuff/foo').and_return('bar')
      @memory_bucket.should_receive(:ls).with(nil).and_return(:some_assets)
      @blackhole_bucket.should_not_receive(:read)
      @blackhole_bucket.should_not_receive(:ls)
      
      @bucket_chain.read('stuff/foo').should == 'bar'
      @bucket_chain.ls.should == :some_assets
    end
  end
end