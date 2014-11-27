require 'spec_helper'

class S3Cloud < AssetCloud::Base
  bucket :tmp, AssetCloud::S3Bucket
end

describe 'Remote test for AssetCloud::S3Bucket', if:  ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY'] && ENV['S3_BUCKET_NAME'] do
  require 'aws-sdk'

  directory = File.dirname(__FILE__) + '/files'

  before(:all) do
    AssetCloud::S3Bucket.configure do |config|
      config.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
      config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
      config.s3_bucket_name = ENV['S3_BUCKET_NAME']
    end

    @cloud = S3Cloud.new(directory , 'http://assets/files' )
    @bucket = @cloud.buckets[:tmp]
  end

  after(:all) do
    ls = @bucket.ls('tmp')
    ls.each { |key| @bucket.delete(key) }
    AssetCloud::S3Bucket.reset_config
  end

  it "#ls should return assets with proper keys" do
    @cloud['tmp/test1.txt'] = 'test1'
    @cloud['tmp/test2.txt'] = 'test2'

    ls = @bucket.ls('tmp')

    ls.first.class.should == AssetCloud::Asset
    keys = ls.map(&:key)
    ['tmp/test1.txt', 'tmp/test2.txt'].all? {|key| keys.include? key }
  end

  it "#delete should ignore errors when deleting" do
    @bucket.delete('tmp/a_file_that_should_not_exist.txt')
  end

  it "#delete should always return true" do
    @cloud['tmp/test1.txt'] = 'test1'

    @bucket.delete('tmp/test1.txt').should == true
  end

  it "#stat should get metadata from S3" do
    start_time = Time.now
    value = 'hello world'
    @cloud.build('tmp/new_file.test', value).store
    metadata = @bucket.stat('tmp/new_file.test')
    metadata.size.should == value.size
    metadata.updated_at.should >= start_time
  end

  it "#read " do
    value = 'hello world'
    key = 'tmp/new_file.txt'
    @bucket.write(key, value)
    data = @bucket.read(key)
    data.should == value
  end

  describe 'when using io' do
    it "should create a new file, and append after creation" do
      key = 'tmp/new_file.test'
      io = @cloud[key].io
      io << 'hello'
      io << ' '
      io << 'world'
      io.close

      @cloud[key].value.should == 'hello world'
    end
  end
end
