require 'spec_helper'

class RemoteS3Cloud < AssetCloud::Base
  attr_accessor :s3_connection
  bucket :tmp, AssetCloud::S3Bucket

  def s3_bucket(key)
    s3_connection.buckets[ENV['S3_BUCKET_NAME']]
  end
end

describe 'Remote test for AssetCloud::S3Bucket', if:  ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY'] && ENV['S3_BUCKET_NAME'] do
  require 'aws-sdk'

  directory = File.dirname(__FILE__) + '/files'

  before(:all) do
    AWS.config({
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    })
    @cloud = RemoteS3Cloud.new(directory , 'testing/assets/files' )
    @cloud.s3_connection = AWS::S3.new()
    @bucket = @cloud.buckets[:tmp]
  end

  after(:all) do
    listing = @bucket.ls('tmp')
    listing.each { |object| object.delete }
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
end
