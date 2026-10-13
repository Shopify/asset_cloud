# frozen_string_literal: true

require "spec_helper"
require "mock_s3_interface"

class S3Cloud < AssetCloud::Base
  bucket :tmp, AssetCloud::S3Bucket
  attr_accessor :s3_connection, :s3_bucket_name

  def s3_bucket(_key)
    s3_connection.bucket(s3_bucket_name)
  end
end

class RootS3Cloud < AssetCloud::Base
  bucket AssetCloud::S3Bucket
  attr_accessor :s3_connection, :s3_bucket_name

  def s3_bucket(_key)
    s3_connection.bucket(s3_bucket_name)
  end
end

describe AssetCloud::S3Bucket do
  directory = File.dirname(__FILE__) + "/files"

  before(:all) do
    @cloud = S3Cloud.new(directory, "http://assets/files")
    @cloud.s3_connection = MockS3Interface.new("a", "b")
    @cloud.s3_bucket_name = "asset-cloud-test"

    @bucket = @cloud.buckets[:tmp]
    FileUtils.mkdir_p(directory + "/tmp")
  end

  after(:each) do
    FileUtils.rm_rf(directory + "/tmp")
  end

  it "#ls should return assets with proper keys" do
    collection = ["#{@cloud.url}/tmp/blah.gif", "#{@cloud.url}/tmp/add_to_cart.gif"].map do |key|
      MockS3Interface::S3Object.new(nil, key)
    end
    expect_any_instance_of(MockS3Interface::Bucket).to(receive(:objects).and_return(collection))

    ls = @bucket.ls("tmp")

    expect(ls).to(all(be_an(AssetCloud::Asset)))
    expect(ls.map(&:key) - ["tmp/blah.gif", "tmp/add_to_cart.gif"]).to(be_empty)
  end

  it "#delete should not ignore errors when deleting" do
    expect_any_instance_of(MockS3Interface::NullS3Object).to(receive(:delete).and_raise(StandardError))

    expect { @bucket.delete("assets/fail.gif") }.to(raise_error(StandardError))
  end

  it "#delete should always return true" do
    expect_any_instance_of(MockS3Interface::NullS3Object).to(receive(:delete).and_return(nil))

    expect(@bucket.delete("assets/fail.gif")).to(eq(true))
  end

  it "#stat should get metadata from S3" do
    value = "hello world"
    @cloud.build("tmp/new_file.test", value).store
    metadata = @bucket.stat("tmp/new_file.test")
    expect(metadata.size).to(eq(value.size))
    expect(metadata.updated_at).to(eq(Time.parse("Mon Aug 27 17:37:51 UTC 2007")))
  end

  it "#read " do
    value = "hello world"
    key = "tmp/new_file.txt"
    @bucket.write(key, value)
    data = @bucket.read(key)
    expect(data).to(eq(value))
  end

  describe "with a relative path prefix" do
    before(:each) do
      @prefixed_cloud = RootS3Cloud.new(directory, "tenant-a/assets")
      @prefixed_cloud.s3_connection = MockS3Interface.new("a", "b")
      @prefixed_cloud.s3_bucket_name = "asset-cloud-test"
      @s3_bucket = @prefixed_cloud.s3_bucket(nil)
    end

    it "#write writes to keys already under the prefix without changing them" do
      ["tenant-a/assets/logo.png", "tenant-a/assets"].each do |key|
        @prefixed_cloud.write(key, "contents")

        expect(@s3_bucket.object(key).get.body).to(eq("contents"))
      end
    end

    it "#read cannot reach an object under a sibling prefix" do
      @s3_bucket.object("tenant-a/assets_other/private.txt").put(body: "secret")

      expect { @prefixed_cloud.read("tenant-a/assets_other/private.txt") }
        .to(raise_error(AssetCloud::AssetNotFoundError))
    end

    it "#write cannot overwrite an object under a sibling prefix" do
      @s3_bucket.object("tenant-a/assets_other/private.txt").put(body: "secret")

      @prefixed_cloud.write("tenant-a/assets_other/private.txt", "overwritten")

      expect(@s3_bucket.object("tenant-a/assets_other/private.txt").get.body).to(eq("secret"))
      expect(@s3_bucket.object("tenant-a/assets/tenant-a/assets_other/private.txt").get.body).to(eq("overwritten"))
    end
  end
end
