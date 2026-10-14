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

  it "#write writes String content into the bucket" do
    value = "hello world"
    key = "test/key.txt"

    expect { @bucket.write(key, value) }.not_to(output.to_stderr)

    expect(@bucket.created_files).to(include([have_attributes(string: value), "s#{@cloud.url}/#{key}", {}]))
  end

  it "#write writes binary String content with null bytes without a warning" do
    value = "\xFF\x00asset content".b
    key = "test/binary.bin"

    expect { @bucket.write(key, value) }.not_to(output.to_stderr)

    expect(@bucket.created_files).to(include([have_attributes(string: value), "s#{@cloud.url}/#{key}", {}]))
  end

  it "#write writes String content with a path-incompatible encoding without a warning" do
    value = "asset content".encode("UTF-16LE")
    key = "test/utf16.txt"

    expect { @bucket.write(key, value) }.not_to(output.to_stderr)

    expect(@bucket.created_files).to(include([have_attributes(string: value), "s#{@cloud.url}/#{key}", {}]))
  end

  it "#write writes a file into the bucket with metadata" do
    value = "hello world"
    key = "test/key.txt"
    metadata = {
      "X-Robots-Tag" => "none",
    }

    @bucket.write(key, value, metadata: metadata)

    expect(@bucket.created_files).to(include([
      have_attributes(string: value),
      "s#{@cloud.url}/#{key}",
      { metadata: metadata },
    ]))
  end

  it "#write writes a file into the bucket with acl" do
    value = "hello world"
    key = "test/key.txt"
    acl = "public"

    @bucket.write(key, value, acl: acl)
    expect(@bucket.created_files).to(include([have_attributes(string: value), "s#{@cloud.url}/#{key}", { acl: acl }]))
  end

  it "#write writes a file into the bucket with content_disposition" do
    value = "hello world"
    key = "test/key.txt"
    content_disposition = "attachment"

    @bucket.write(key, value, content_disposition: content_disposition)

    expect(@bucket.created_files).to(include([
      have_attributes(string: value),
      "s#{@cloud.url}/#{key}",
      { content_disposition: content_disposition },
    ]))
  end

  it "#write passes an existing IO object through unchanged" do
    data = StringIO.new("hello world")
    key = "test/io.txt"
    expect(@bucket).to(receive(:create_file).with(data, "s#{@cloud.url}/#{key}").and_return(:uploaded_file))

    expect(@bucket.write(key, data)).to(eq(:uploaded_file))
  end

  it "#write passes an open File through unchanged" do
    key = "test/file.txt"

    File.open("#{directory}/products/key.txt", "rb") do |file|
      expect(@bucket).to(receive(:create_file).with(file, "s#{@cloud.url}/#{key}"))

      @bucket.write(key, file)
    end
  end

  it "#write uploads a String path as literal content through the GCS client" do
    service = Google::Cloud::Storage::Service.new("test-project", nil)
    gcs_bucket = Google::Cloud::Storage::Bucket.new_lazy("test-bucket", service)
    allow(@cloud).to(receive(:gcs_bucket).and_return(gcs_bucket))
    bucket = AssetCloud::GCSBucket.new(@cloud, "")
    local_path = "#{directory}/products/key.txt"
    uploaded_content = nil

    expect(service.service).to(receive(:execute_or_queue_command)) do |command|
      command.prepare!
      uploaded_content = command.upload_io.read
      Google::Apis::StorageV1::Object.new(name: "test/path.txt")
    ensure
      command.release!
    end

    expect { bucket.write("test/path.txt", local_path) }.to(output(
      "AssetCloud::GCSBucket#write treats String paths as literal content. " \
        "Pass an open File or IO object to upload file contents.\n",
    ).to_stderr)

    expect(uploaded_content).to(eq(local_path))
    expect(uploaded_content).not_to(eq(File.binread(local_path)))
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

  describe "#write with a path prefix" do
    let(:local_path) { "#{directory}/products/key.txt" }

    before do
      @cloud = GCSCloud.new(directory, "/assets/files")
      @bucket = MockGCSBucket.new(@cloud, "")
      allow(@cloud).to(receive(:gcs_bucket).and_return(@bucket))
    end

    it "writes to keys already under the prefix without changing them" do
      key = "s#{@cloud.url}/test/key.txt"
      prefix = "s#{@cloud.url}"

      @bucket.write(key, local_path)
      @bucket.write(prefix, local_path)

      expect(@bucket.created_files).to(eq([
        [local_path, key, {}],
        [local_path, prefix, {}],
      ]))
    end

    it "writes to the unchanged key when the prefix ends with a slash" do
      @cloud.url += "/"
      key = "s#{@cloud.url}test/key.txt"

      @bucket.write(key, local_path)

      expect(@bucket.created_files).to(eq([[local_path, key, {}]]))
    end

    it "writes to the unchanged key when the prefix is empty" do
      @bucket = Class.new(MockGCSBucket) do
        def path_prefix
          ""
        end
      end.new(@cloud, "")
      allow(@cloud).to(receive(:gcs_bucket).and_return(@bucket))
      key = "deployments/key.txt"

      @bucket.write(key, local_path)

      expect(@bucket.created_files).to(eq([[local_path, key, {}]]))
    end
  end

  it "#write does not write to a sibling prefix" do
    local_path = "#{directory}/products/key.txt"
    sibling = "s#{@cloud.url}_other/private.txt"

    @bucket.write(sibling, local_path)

    expect(@bucket.created_files).to(include([local_path, "s#{@cloud.url}/#{sibling}", {}]))
    expect(@bucket.created_files.map { |f| f[1] }).not_to(include(sibling))
  end
end
