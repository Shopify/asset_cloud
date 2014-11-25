require 'spec_helper'
require 'mock_s3_interface'

class S3Cloud < AssetCloud::Base
  bucket :s3, AssetCloud::S3Bucket
  bucket :tmp, AssetCloud::S3Bucket
end

describe AssetCloud::S3Bucket do
  directory = File.dirname(__FILE__) + '/files'

  before do
    AssetCloud::S3Bucket.s3_connection = MockS3Interface.new('a', 'b')
    @cloud = S3Cloud.new(directory , 'http://assets/files' )
    @bucket = @cloud.buckets[:s3]
    FileUtils.mkdir_p(directory + '/tmp')
  end

  after do
    FileUtils.rm_rf(directory + '/tmp')
    #AssetCloud::S3Bucket.s3_bucket.clear
  end

=begin
  describe "operations not supported" do
    it "#ls not supported" do
      expect { @bucket.ls('foo')}.to raise_error NotImplementedError
    end
  end
=end
  it "#ls should return assets with proper keys" do
    expect_any_instance_of(MockS3Interface::Bucket).to receive(:objects).and_return(MockS3Interface::Collection.new(nil, ["s#{@cloud.url}/assets/blah.gif", "s#{@cloud.url}/assets/add_to_cart.gif"]))
    ls = @bucket.ls('assets')
    ls.first.class.should == AssetCloud::Asset
    ls.map(&:key).should == ['assets/blah.gif', 'assets/add_to_cart.gif']
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

  it "#write does not change the encoding of the passed in data" do
    data = 'uft-8'.encode('UTF-8')
    @bucket.write('key', data)

    data.encoding.should == Encoding::UTF_8
  end

  it "BOM_MARKERS all have encodings available to rails" do
    AssetCloud::S3Bucket::BOM_MARKERS.each do |encoding, marking|
      Encoding.find(encoding).should_not == nil
    end
  end

  it "#read returns data encoding which matches the BOM" do
    encoding_data = {
      'UTF-8'     => "\xEF\xBB\xBF\xC3\xBC".force_encoding('binary'),
      'UTF-16BE'  => "\xFE\xFF\x00\x7A".force_encoding('binary'),
      'UTF-16LE'  => "\xFF\xFE\x7A\x00".force_encoding('binary'),
      'UTF-32BE'  => "\x00\x00\xFE\xFF\x00\x00\x00\x9C".force_encoding('binary'),
      'UTF-32LE'  => "\xFF\xFE\x00\x00\x9C\x00\x00\x00".force_encoding('binary'),
    }

    encoding_data.each do |encoding, data|
      @cloud['tmp/some.thing'] = data
      bucket_data = @bucket.read('tmp/some.thing')
      bucket_data.should == data.force_encoding(encoding)
      bucket_data.encoding.should == Encoding.find(encoding)
    end
  end

  it "#read should return liquid as UTF-8 if no BOM is present" do
    utf_data = "something 星道ショップý"
    ascii_data = "something \xE6\x98\x9F\xE9\x81\x93\xE3\x82\xB7\xE3\x83\xA7\xE3\x83\x83\xE3\x83\x97\xC3\xBD"
    @cloud['tmp/something.css.liquid'] = ascii_data
    data = @bucket.read('tmp/something.css.liquid')
    data.should == utf_data
    data.encoding.should == Encoding::UTF_8
  end

  it "#read should return css as UTF-8 if no BOM is present" do
    utf_data = "something 星道ショップý"
    ascii_data = "something \xE6\x98\x9F\xE9\x81\x93\xE3\x82\xB7\xE3\x83\xA7\xE3\x83\x83\xE3\x83\x97\xC3\xBD"
    @cloud['tmp/something.css'] = ascii_data
    data = @bucket.read('tmp/something.css')
    assert_equal utf_data, data
    assert_equal Encoding::UTF_8, data.encoding
  end

  it "#read should return BINARY encoded data for anything that doesn't have a BOM and isn't liquid or css" do
    utf_data = "something \xC3\xBC"
    @cloud['tmp/something.png'] = utf_data.force_encoding('BINARY')
    data = @bucket.read('tmp/something.png')
    assert_equal utf_data.force_encoding('BINARY'), data
    assert_equal Encoding::ASCII_8BIT, data.encoding
  end

  it "#read should raise an exception when data is not ASCII-8BIT" do
    utf_data = "something \xC3\xBC"
    #Rails.logger.expects(:warn).with("[PublicS3Bucket#encode_data] Expected data to be ASCII-8BIT but was UTF-8 for assets/something.txt")
    expect_any_instance_of(MockS3Interface::S3Object).to receive(:read).and_return(utf_data.force_encoding('UTF-8'))
    data = @bucket.read('tmp/something.txt')
    data.encoding.should == Encoding::UTF_8
  end

  # this forces the encoding of the data string to ascii-8bit
  # just like the real s3 bucket object.
  class StubS3BucketObject
    def write(data, options)
      data.force_encoding("ASCII-8BIT")
    end
  end
end
