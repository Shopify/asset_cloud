require 'spec_helper'
require 'mock_s3_interface'

class S3Cloud < AssetCloud::Base
  bucket :tmp, AssetCloud::S3Bucket
  attr_accessor :s3_connection, :s3_bucket_name

  def s3_bucket(key)
    s3_connection.buckets[s3_bucket_name]
  end
end

describe AssetCloud::S3Bucket do
  directory = File.dirname(__FILE__) + '/files'

  before(:all) do
    @cloud = S3Cloud.new(directory , 'http://assets/files')
    @cloud.s3_connection = MockS3Interface.new('a', 'b')
    @cloud.s3_bucket_name = 'asset-cloud-test'

    @bucket = @cloud.buckets[:tmp]
    FileUtils.mkdir_p(directory + '/tmp')
  end

  after(:each) do
    FileUtils.rm_rf(directory + '/tmp')
  end

  it "#ls should return assets with proper keys" do
    collection = MockS3Interface::Collection.new(nil, ["#{@cloud.url}/tmp/blah.gif", "#{@cloud.url}/tmp/add_to_cart.gif"])
    expect_any_instance_of(MockS3Interface::Bucket).to receive(:objects).and_return(collection)
    ls = @bucket.ls('tmp')
    ls.first.class.should == AssetCloud::Asset
    ls.map(&:key).should == ['tmp/blah.gif', 'tmp/add_to_cart.gif']
  end

  it "#delete should not ignore errors when deleting" do
    expect_any_instance_of(MockS3Interface::Bucket).to receive(:delete).and_raise(StandardError)

    expect { @bucket.delete('assets/fail.gif') }.to raise_error(StandardError)
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
end
