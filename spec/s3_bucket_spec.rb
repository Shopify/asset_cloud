require 'spec_helper'
require 'mock_s3_interface'

class S3Cloud < AssetCloud::Base
  bucket :tmp, AssetCloud::S3Bucket

  after_io_close :after_io_close_callback
end

describe AssetCloud::S3Bucket do
  directory = File.dirname(__FILE__) + '/files'

  before(:all) do
    AssetCloud::S3Bucket.configure do |config|
      config.aws_s3_connection = MockS3Interface.new('a', 'b')
      config.s3_bucket_name = 'asset-cloud-test'
    end

    @cloud = S3Cloud.new(directory , 'http://assets/files' )
    @bucket = @cloud.buckets[:tmp]
    FileUtils.mkdir_p(directory + '/tmp')
  end

  after(:each) do
    FileUtils.rm_rf(directory + '/tmp')
  end

  after(:all) do
    AssetCloud::S3Bucket.reset_config
  end

  it "#ls should return assets with proper keys" do
    collection = MockS3Interface::Collection.new(nil, ["s#{@cloud.url}/tmp/blah.gif", "s#{@cloud.url}/tmp/add_to_cart.gif"])
    expect_any_instance_of(MockS3Interface::Bucket).to receive(:objects).and_return(collection)
    ls = @bucket.ls('tmp')
    ls.first.class.should == AssetCloud::Asset
    ls.map(&:key).should == ['tmp/blah.gif', 'tmp/add_to_cart.gif']
  end

  it "#delete should ignore errors when deleting" do
    expect_any_instance_of(MockS3Interface::Bucket).to receive(:delete).and_raise(StandardError)

    @bucket.delete('assets/fail.gif')
  end

  it "#delete should always return true" do
    expect_any_instance_of(MockS3Interface::Bucket).to receive(:delete).and_return(nil)

    @bucket.delete('assets/fail.gif').should == true
  end

  it "#stat should get metadata from S3" do
    value = 'hello world'
    @cloud.build('tmp/new_file.test', value).store
    metadata = @bucket.stat('tmp/new_file.test')
    metadata.size.should == value.size
    metadata.updated_at.should == Time.parse("Mon Aug 27 17:37:51 UTC 2007")
  end

  it "#read " do
    value = 'hello world'
    key = 'tmp/new_file.txt'
    @bucket.write(key, value)
    data = @bucket.read(key)
    data.should == value
  end

  describe 'when using io' do
    it "#stat should get metadata from S3" do
      key = 'tmp/new_file.test'
      value = 'hello world'
      @cloud.should_receive(:after_io_close_callback).with(key, an_instance_of(MockS3Interface::MockMultipartUpload)).and_return(true)
      io = @cloud[key].io
      io << 'hello'
      io << ' '
      io << 'world'
      io.close

      metadata = @bucket.stat(key)
      metadata.size.should == value.size
      metadata.updated_at.should == Time.parse("Mon Aug 27 17:37:51 UTC 2007")
    end

    it "#read " do
      value = 'hello world'
      key = 'tmp/new_file.txt'
      @cloud.should_receive(:after_io_close_callback).with(key, an_instance_of(MockS3Interface::MockMultipartUpload)).and_return(true)
      io = @cloud[key].io
      io << 'hello'
      io << ' '
      io << 'world'
      io.close

      data = @bucket.read(key)
      data.should == value
    end

    it "should create a new file, and append after creation" do
      key = 'tmp/new_file.test'
      @cloud.should_receive(:after_io_close_callback).with(key, an_instance_of(MockS3Interface::MockMultipartUpload)).and_return(true)
      io = @cloud[key].io
      io << 'hello'
      io << ' '
      io << 'world'
      io.close

      @cloud[key].value.should == 'hello world'
    end

    it "should delete aborted files" do
      key = 'tmp/new_file.test'
      io = @cloud[key].io
      io << 'hello'
      io << ' '
      io << 'world'
      io.abort

      expect {@cloud[key].value}.to raise_error(AssetCloud::AssetNotFoundError)
    end
  end
end
