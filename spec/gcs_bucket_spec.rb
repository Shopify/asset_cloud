# frozen_string_literal: true

require "spec_helper"
require "google/cloud/storage"

class GCSCloud < AssetCloud::Base
end

class MockGCSBucket < AssetCloud::GCSBucket
  def files(prefix: nil)
  end

  def file(key)
  end

  def create_file(data, key, options = {})
    created_files << [data, key, options]
  end

  def created_files
    @created_files ||= []
  end
end

describe AssetCloud::GCSBucket do
  directory = File.dirname(__FILE__) + "/files"

  before(:all) do
    @cloud = GCSCloud.new(directory, "/assets/files")
    @bucket = MockGCSBucket.new(@cloud, "")
  end

  it "#ls with no arguments returns all files in the bucket" do
    expect_any_instance_of(GCSCloud).to(receive(:gcs_bucket).and_return(@bucket))
    expect_any_instance_of(MockGCSBucket).to(receive(:files).with(no_args).and_return(nil))
    @bucket.ls
  end

  it "#ls with arguments returns the file" do
    key = "test/ls.txt"
    expect_any_instance_of(MockGCSBucket).to(receive(:file).with("s#{@cloud.url}/#{key}")
      .and_return(Google::Cloud::Storage::File.new))

    file = @bucket.ls(key)
    expect(file.class).to(eq(Google::Cloud::Storage::File))
  end

  it "#write writes a file into the bucket" do
    local_path = "#{directory}/products/key.txt"
    key = "test/key.txt"

    @bucket.write(key, local_path)

    expect(@bucket.created_files).to(include([local_path, "s#{@cloud.url}/#{key}", {}]))
  end

  it "#write writes a file into the bucket with metadata" do
    local_path = "#{directory}/products/key.txt"
    key = "test/key.txt"
    metadata = {
      "X-Robots-Tag" => "none",
    }

    @bucket.write(key, local_path, metadata: metadata)

    expect(@bucket.created_files).to(include([local_path, "s#{@cloud.url}/#{key}", { metadata: metadata }]))
  end

  it "#write writes a file into the bucket with acl" do
    local_path = "#{directory}/products/key.txt"
    key = "test/key.txt"
    acl = "public"

    @bucket.write(key, local_path, acl: acl)
    expect(@bucket.created_files).to(include([local_path, "s#{@cloud.url}/#{key}", { acl: acl }]))
  end

  it "#write writes a file into the bucket with content_disposition" do
    local_path = "#{directory}/products/key.txt"
    key = "test/key.txt"
    content_disposition = "attachment"

    @bucket.write(key, local_path, content_disposition: content_disposition)

    expect(@bucket.created_files).to(include([
      local_path,
      "s#{@cloud.url}/#{key}",
      { content_disposition: content_disposition },
    ]))
  end

  it "#delete removes the file from the bucket" do
    key = "test/key.txt"
    expect_any_instance_of(MockGCSBucket).to(receive(:file).with("s#{@cloud.url}/#{key}")
      .and_return(Google::Cloud::Storage::File.new))
    expect_any_instance_of(Google::Cloud::Storage::File).to(receive(:delete).with(no_args))

    expect do
      @bucket.delete(key)
    end.not_to(raise_error)
  end

  it "#read returns the data of the file" do
    value = "hello world"
    key = "tmp/new_file.txt"
    expect_any_instance_of(MockGCSBucket).to(receive(:file).with("s#{@cloud.url}/#{key}")
      .and_return(Google::Cloud::Storage::File.new))
    expect_any_instance_of(Google::Cloud::Storage::File).to(receive(:download)
      .and_return(StringIO.new(value)))

    data = @bucket.read(key)
    expect(data).to(eq(value))
  end

  it "#read raises AssetCloud::AssetNotFoundError if the file is not found" do
    key = "tmp/not_found.txt"
    expect_any_instance_of(MockGCSBucket).to(receive(:file).with("s#{@cloud.url}/#{key}").and_return(nil))
    expect do
      @bucket.read(key)
    end.to(raise_error(AssetCloud::AssetNotFoundError))
  end

  it "#stat returns information on the asset" do
    key = "tmp/new_file.txt"
    expected_time = Time.now
    expected_size = 1

    expect_any_instance_of(MockGCSBucket).to(receive(:file).with("s#{@cloud.url}/#{key}")
      .and_return(Google::Cloud::Storage::File.new))
    expect_any_instance_of(Google::Cloud::Storage::File).to(receive(:size).and_return(expected_size))
    expect_any_instance_of(Google::Cloud::Storage::File).to(receive(:created_at).and_return(expected_time))
    expect_any_instance_of(Google::Cloud::Storage::File).to(receive(:updated_at).and_return(expected_time))

    stats = @bucket.stat(key)
    expect(stats.size).to(eq(expected_size))
    expect(stats.created_at).to(eq(expected_time))
    expect(stats.updated_at).to(eq(expected_time))
  end
end
