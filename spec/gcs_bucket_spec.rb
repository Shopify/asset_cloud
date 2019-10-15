require 'spec_helper'
require 'google/cloud/storage'

class GCSCloud < AssetCloud::Base
end

class MockGCSBucket < AssetCloud::GCSBucket
  def files(prefix: nil)
  end

  def file(key)
  end

  def create_file(data, key)
  end
end

describe AssetCloud::GCSBucket do
  directory = File.dirname(__FILE__) + '/files'

  before(:all) do
    @cloud = GCSCloud.new(directory, '/assets/files')
    @bucket = MockGCSBucket.new(@cloud, '')
  end

  it "#ls with no arguments returns all files in the bucket" do
    expect_any_instance_of(GCSCloud).to receive(:gcs_bucket).and_return(@bucket)
    expect_any_instance_of(MockGCSBucket).to receive(:files).with(no_args).and_return(nil)
    @bucket.ls
  end

  it "#ls with arguments returns the file" do
    key = 'test/ls.txt'
    expect_any_instance_of(MockGCSBucket).to receive(:file).with("s#{@cloud.url}/#{key}").and_return(Google::Cloud::Storage::File.new)

    file = @bucket.ls(key)
    expect(file.class).to eq(Google::Cloud::Storage::File)
  end

  it "#write writes a file into the bucket" do
    local_path = "#{directory}/products/key.txt"
    key = 'test/key.txt'
    expect_any_instance_of(MockGCSBucket).to receive(:create_file).with(local_path, "s#{@cloud.url}/#{key}").and_return(Google::Cloud::Storage::File.new)
    expect_any_instance_of(Google::Cloud::Storage::File::Acl).to receive(:private!)

    @bucket.write(key, local_path)
  end

  it "#write writes a public file into the bucket" do
    local_path = "#{directory}/products/key.txt"
    key = 'test/key.txt'
    expect_any_instance_of(MockGCSBucket).to receive(:create_file).with(local_path, "s#{@cloud.url}/#{key}").and_return(Google::Cloud::Storage::File.new)
    expect_any_instance_of(Google::Cloud::Storage::File::Acl).to receive(:public!)

    @bucket.write(key, local_path, acl: :public)
  end

  it "#delete removes the file from the bucket" do
    key = 'test/key.txt'
    expect_any_instance_of(MockGCSBucket).to receive(:file).with("s#{@cloud.url}/#{key}").and_return(Google::Cloud::Storage::File.new)
    expect_any_instance_of(Google::Cloud::Storage::File).to receive(:delete).with(no_args)

    expect do
      @bucket.delete(key)
    end.not_to raise_error
  end

  it "#read returns the data of the file" do
    value = 'hello world'
    key = 'tmp/new_file.txt'
    expect_any_instance_of(MockGCSBucket).to receive(:file).with("s#{@cloud.url}/#{key}").and_return(Google::Cloud::Storage::File.new)
    expect_any_instance_of(Google::Cloud::Storage::File).to receive(:download).and_return(StringIO.new(value))

    data = @bucket.read(key)
    data.should == value
  end

  it "#read raises AssetCloud::AssetNotFoundError if the file is not found" do
    key = 'tmp/not_found.txt'
    expect_any_instance_of(MockGCSBucket).to receive(:file).with("s#{@cloud.url}/#{key}").and_return(nil)
    expect do
      @bucket.read(key)
    end.to raise_error(AssetCloud::AssetNotFoundError)
  end

  it "#stat returns information on the asset" do
    value = 'hello world'
    key = 'tmp/new_file.txt'
    expected_time = Time.now
    expected_size = 1

    expect_any_instance_of(MockGCSBucket).to receive(:file).with("s#{@cloud.url}/#{key}").and_return(Google::Cloud::Storage::File.new)
    expect_any_instance_of(Google::Cloud::Storage::File).to receive(:size).and_return(expected_size)
    expect_any_instance_of(Google::Cloud::Storage::File).to receive(:created_at).and_return(expected_time)
    expect_any_instance_of(Google::Cloud::Storage::File).to receive(:updated_at).and_return(expected_time)

    stats = @bucket.stat(key)
    expect(stats.size).to eq(expected_size)
    expect(stats.created_at).to eq(expected_time)
    expect(stats.updated_at).to eq(expected_time)
  end
end
