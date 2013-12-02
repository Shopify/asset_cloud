require 'spec_helper'

class ChainedCloud < AssetCloud::Base
  bucket :stuff, AssetCloud::BucketChain.chain( AssetCloud::MemoryBucket,
                                                AssetCloud::MemoryBucket,
                                                AssetCloud::FileSystemBucket )

  bucket :versioned_stuff, AssetCloud::BucketChain.chain( AssetCloud::FileSystemBucket,
                                                          AssetCloud::VersionedMemoryBucket,
                                                          AssetCloud::MemoryBucket )
end

describe AssetCloud::BucketChain do
  directory = File.dirname(__FILE__) + '/files'

  before(:each) do
    @cloud = ChainedCloud.new(directory , 'http://assets/files' )
    @bucket_chain = @cloud.buckets[:stuff]
    @chained_buckets = @bucket_chain.chained_buckets
    @chained_buckets.each {|b| b.ls('stuff').each {|asset| asset.delete}}

    @versioned_stuff = @cloud.buckets[:versioned_stuff]
  end

  describe ".chain" do
    it 'should take multiple Bucket classes and return a new Bucket class' do
      @bucket_chain.should be_a_kind_of(AssetCloud::BucketChain)
    end
  end

  describe "#write" do
    it 'should write to each sub-bucket when everything is kosher and return the result of the first write' do
      @chained_buckets.each do |bucket|
        bucket.should_receive(:write).with('stuff/foo', 'successful creation').and_return('successful creation')
      end

      @bucket_chain.write('stuff/foo', 'successful creation').should == 'successful creation'
    end
    it 'should roll back creation-writes and re-raise an error when a bucket raises one' do
      @chained_buckets.last.should_receive(:write).with('stuff/foo', 'unsuccessful creation').and_raise('hell')
      @chained_buckets[0..-2].each do |bucket|
        bucket.should_receive(:write).with('stuff/foo', 'unsuccessful creation').and_return(true)
        bucket.should_receive(:delete).with('stuff/foo').and_return(true)
      end

      lambda { @bucket_chain.write('stuff/foo', 'unsuccessful creation') }.should raise_error(RuntimeError)
    end
    it 'should roll back update-writes and re-raise an error when a bucket raises one' do
      @bucket_chain.write('stuff/foo', "original value")

      @chained_buckets.last.should_receive(:write).with('stuff/foo', 'new value').and_raise('hell')

      lambda { @bucket_chain.write('stuff/foo', 'new value') }.should raise_error(RuntimeError)
      @chained_buckets.each do |bucket|
        bucket.read('stuff/foo').should == 'original value'
      end
    end
  end

  describe "#delete" do
    it 'should delete from each sub-bucket when everything is kosher' do
      @bucket_chain.write('stuff/foo', "successful deletion comin' up")

      @chained_buckets.each do |bucket|
        bucket.should_receive(:delete).with('stuff/foo').and_return(true)
      end

      @bucket_chain.delete('stuff/foo')
    end
    it 'should roll back deletions and re-raise an error when a bucket raises one' do
      @bucket_chain.write('stuff/foo', "this deletion will fail")

      @chained_buckets.last.should_receive(:delete).with('stuff/foo').and_raise('hell')
      @chained_buckets[0..-2].each do |bucket|
        bucket.should_receive(:delete).with('stuff/foo').and_return(true)
        bucket.should_receive(:write).with('stuff/foo', 'this deletion will fail').and_return(true)
      end

      lambda { @bucket_chain.delete('stuff/foo') }.should raise_error(RuntimeError)
    end
  end

  describe "#read" do
    it 'should read from only the first available sub-bucket' do
      @chained_buckets[0].should_receive(:read).with('stuff/foo').and_raise(NotImplementedError)
      @chained_buckets[0].should_receive(:ls).with(nil).and_raise(NoMethodError)
      @chained_buckets[0].should_receive(:stat).and_return(:metadata)

      @chained_buckets[1].should_receive(:read).with('stuff/foo').and_return('bar')
      @chained_buckets[1].should_receive(:ls).with(nil).and_return(:some_assets)
      @chained_buckets[1].should_not_receive(:stat)

      @chained_buckets[2..-1].each do |bucket|
        bucket.should_not_receive(:read)
        bucket.should_not_receive(:ls)
        bucket.should_not_receive(:stat)
      end

      @bucket_chain.read('stuff/foo').should == 'bar'
      @bucket_chain.ls.should == :some_assets
      @bucket_chain.stat.should == :metadata
    end
  end


  describe "#read_version" do
    it 'should read from only the first available sub-bucket' do
      buckets = @versioned_stuff.chained_buckets

      buckets[1].should_receive(:read_version).with('stuff/foo',3).and_return('bar')
      buckets.last.should_not_receive(:read_version)

      @versioned_stuff.read_version('stuff/foo', 3).should == 'bar'
    end
  end

  describe "#versions" do
    it 'should read from only the first available sub-bucket' do
      buckets = @versioned_stuff.chained_buckets

      buckets[1].should_receive(:versions).with('versioned_stuff/foo').and_return([1,2,3])
      buckets.last.should_not_receive(:versions)

      @versioned_stuff.versions('versioned_stuff/foo').should == [1,2,3]
    end
  end

  describe "with versioned buckets" do
    it 'should store and retrieve versions seamlessly' do
      %w{one two three}.each do |content|
        @cloud['versioned_stuff/foo'] = content
      end
      asset = @cloud['versioned_stuff/foo']
      asset.value.should == 'three'
      asset.rollback(1).value.should == 'one'
      asset.versions.should == [1,2,3]
      asset.value = 'four'
      asset.store
      asset.versions.should == [1,2,3,4]
    end
  end

  describe '#respond_to?' do
    it 'should return true if any chained buckets respond to the given method' do
      @bucket_chain.respond_to?(:foo).should == false
      @chained_buckets[1].should_receive(:respond_to?).with(:bar).and_return(true)
      @bucket_chain.respond_to?(:bar).should == true
    end
  end

  describe '#method_missing' do
    it 'should try each bucket' do
      @chained_buckets[1].should_receive(:buzz).and_return(true)
      @chained_buckets[2].should_not_receive(:buzz)
      @bucket_chain.buzz.should == true
    end
  end
end
