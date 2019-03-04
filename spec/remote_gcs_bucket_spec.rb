# frozen_string_literal: true

# rubocop:disable RSpec/FilePath, Lint/MissingCopEnableDirective

class RemoteGCSCloud < AssetCloud::Base
  attr_accessor :gcs_connection
  bucket :tmp, AssetCloud::GcsBucket

  def gcs_bucket
    gcs_connection.bucket ENV['GCS_BUCKET']
  end
end

describe AssetCloud::GcsBucket, if: ENV['GCS_PROJECT_ID'] &&
                                    ENV['GCS_KEY'] && ENV['GCS_BUCKET'] do
  require 'google/cloud/storage'

  directory = File.dirname(__FILE__) + '/files'
  local_path = directory + '/stuff/test_img/shopify_logo.png'
  fake_path = directory + '/stuff/test_img.fake.png'
  write_to = directory + '/stuff/download/shopify.png'
  storage_path = 'shopify.png'

  let(:cloud) { RemoteGCSCloud.new(directory) }
  let(:bucket) { cloud.buckets[:tmp] }

  before do
    cloud.gcs_connection = Google::Cloud::Storage.new(
      project_id: ENV['GCS_PROJECT_ID'],
      keyfile: ENV['GCS_KEY']
    )
  end

  after do
    dir_path = File.dirname(__FILE__) + '/files/stuff/download'
    Dir.foreach(dir_path) do |f|
      fn = File.join(dir_path, f)
      File.delete(fn) if f != '.' && f != '..'
    end
    bucket.clear
  end

  # testing write
  it '#writes a file to the bucket' do
    expect do
      bucket.write(local_path, storage_path)
    end.not_to raise_error
  end

  it 'throws a NoMethodError when #writing a non-eistent file' do
    expect do
      bucket.write(fake_path, storage_path)
    end.to raise_error(ArgumentError)
  end

  # testing read
  it '#reads a file to the specified path from the bucket' do
    bucket.write(local_path, storage_path)

    expect do
      bucket.read('shopify.png', write_to)
    end.not_to raise_error
  end

  it 'throws NoMethodError when trying to #read a non-existent file' do
    expect do
      bucket.read('a_file_that_does_not_exist.jpg', write_to)
    end.to raise_error(NoMethodError)
  end

  # testing delete
  it 'throws a NoMethodError raised #deleting a non-existent file' do
    expect do
      bucket.delete('a_file_that_does_not_exist.jpg')
    end.to raise_error(NoMethodError)
  end

  it '#deletes a file from the bucket as specified' do
    bucket.write(local_path, storage_path)
    expect do
      bucket.delete(storage_path)
    end.not_to raise_error
  end

  # testing ls
  it '#lists the items in the bucket given no prefix' do
    bucket.write(local_path, storage_path)
    all_files = bucket.ls
    all_files.length.should.equal?(1)
  end

  it '#lists files according to their prefix' do
    bucket.write(local_path, storage_path)
    no_files = bucket.ls('invalid_prefix')
    no_files.length.should.equal?(0)
    all_files = bucket.ls('shopify')
    all_files.length.should.equal?(1)
  end
end
