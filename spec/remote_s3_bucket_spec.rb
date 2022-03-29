# frozen_string_literal: true

require "spec_helper"

class RemoteS3Cloud < AssetCloud::Base
  attr_accessor :s3_connection

  bucket :tmp, AssetCloud::S3Bucket

  def s3_bucket(_key)
    s3_connection.bucket(ENV["S3_BUCKET_NAME"])
  end
end

describe "Remote test for AssetCloud::S3Bucket",
  if: ENV["AWS_ACCESS_KEY_ID"] && ENV["AWS_SECRET_ACCESS_KEY"] && ENV["S3_BUCKET_NAME"] do
  directory = File.dirname(__FILE__) + "/files"

  before(:all) do
    Aws.config = {
      region: ENV.fetch("AWS_REGION", "us-east-1"),
      credentials: Aws::Credentials.new(
        ENV["AWS_ACCESS_KEY_ID"],
        ENV["AWS_SECRET_ACCESS_KEY"],
      ),
    }

    @cloud = RemoteS3Cloud.new(directory, "testing/assets/files")
    @cloud.s3_connection = Aws::S3::Resource.new
    @bucket = @cloud.buckets[:tmp]
  end

  after(:all) do
    listing = @bucket.ls("tmp")
    listing.each(&:delete)
  end

  it "#ls should return assets with proper keys" do
    @cloud["tmp/test1.txt"] = "test1"
    @cloud["tmp/test2.txt"] = "test2"

    ls = @bucket.ls("tmp")

    expect(ls).to(all(be_an(AssetCloud::Asset)))
    expect(ls.map(&:key) - ["tmp/test1.txt", "tmp/test2.txt"]).to(be_empty)
  end

  it "#ls returns all assets" do
    @cloud["tmp/test1.txt"] = "test1"
    @cloud["tmp/test2.txt"] = "test2"

    ls = @bucket.ls

    expect(ls).to(all(be_an(AssetCloud::Asset)))
    expect(ls.map(&:key) - ["tmp/test1.txt", "tmp/test2.txt"]).to(be_empty)
  end

  it "#delete should ignore errors when deleting" do
    @bucket.delete("tmp/a_file_that_should_not_exist.txt")
  end

  it "#delete should always return true" do
    @cloud["tmp/test1.txt"] = "test1"

    expect(@bucket.delete("tmp/test1.txt")).to(eq(true))
  end

  it "#stat should get metadata from S3" do
    start_time = Time.now
    value = "hello world"
    @cloud.build("tmp/new_file.test", value).store
    metadata = @bucket.stat("tmp/new_file.test")
    expect(metadata.size).to(eq(value.size))
    expect(metadata.updated_at).to(be >= start_time)
  end

  it "#stat a missing asset" do
    metadata = @bucket.stat("i_do_not_exist_and_never_will.test")
    expect(metadata).to(be_an(AssetCloud::Metadata))
    expect(metadata.exist).to(be(false))
  end

  it "#read " do
    value = "hello world"
    key = "tmp/new_file.txt"
    @bucket.write(key, value)
    data = @bucket.read(key)
    expect(data).to(eq(value))
  end

  it "#read a missing asset" do
    expect { @bucket.read("i_do_not_exist_and_never_will.test") }.to(raise_error(AssetCloud::AssetNotFoundError))
  end

  it "#reads first bytes when passed options" do
    value = "hello world"
    key = "tmp/new_file.txt"
    options = { range: 0...5 }
    @bucket.write(key, value)
    data = @bucket.read(key, options)
    expect(data).to(eq("hello"))
  end
end
