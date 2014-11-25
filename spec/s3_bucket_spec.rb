require 'spec_helper'

class S3Cloud < AssetCloud::Base
  bucket :s3, AssetCloud::S3Bucket
end

describe AssetCloud::S3Bucket do
  directory = File.dirname(__FILE__) + '/files'

  before do
    @cloud = S3Cloud.new(directory , 'http://assets/files' )
  end

  after do
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
    MockS3Interface::Bucket.any_instance.stubs(:objects).returns(MockS3Interface::Collection.new(nil, ["s#{@cloud.url}/assets/blah.gif", "s#{@cloud.url}/assets/add_to_cart.gif"]))
    ls = @bucket.ls('assets')
    assert ls.first.is_a?(AssetCloud::Asset)
    assert_equal ['assets/blah.gif', 'assets/add_to_cart.gif'], ls.map(&:key)
  end

  it "#delete should ignore errors when deleting" do
    IOThread.expects(:push).once
    MockS3Interface::Bucket.any_instance.expects(:delete).raises(StandardError)
    assert_nothing_raised do
      @bucket.delete('assets/fail.gif')
    end
  end

  it "#delete should always return true" do
    IOThread.expects(:push)
    MockS3Interface::Bucket.any_instance.expects(:delete).returns(nil)

    assert @bucket.delete('assets/fail.gif')
  end

  it "#stat should get metadata from S3" do
    @cloud['assets/foo.txt'] = 'foo'
    metadata = @bucket.stat('assets/foo.txt')
    assert_equal 3, metadata.size
    assert_equal Time.parse("Mon Aug 27 17:37:51 UTC 2007"), metadata.updated_at
  end

  it "#write should enqueue an IOThread job" do
    IOThread.expects(:push).with(:write, 's/files/1/2637/1970/t/1/key', 'data', {content_type: 'application/octet-stream', cache_control: 'public, max-age=31557600'}).once
    @bucket.write('key', 'data')
  end

  it "#write does not change the encoding of the passed in data" do
    MockS3Interface::Collection.any_instance.stubs('[]').returns StubS3BucketObject.new
    data = 'uft-8'.encode('UTF-8')

    @bucket.write('key', data)

    assert_equal Encoding::UTF_8, data.encoding
  end

  it "#delete should enqueue an IOThread job" do
    IOThread.expects(:push).with(:delete, 's/files/1/2637/1970/t/1/key').once
    @bucket.delete('key')
  end

  it "BOM_MARKERS all have encodings available to rails" do
    PublicS3Bucket::BOM_MARKERS.each do |encoding, marking|
      assert Encoding.find(encoding)
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
      @cloud['assets/some.thing'] = data
      bucket_data = @bucket.read('assets/some.thing')
      assert_equal data.force_encoding(encoding), bucket_data
      assert_equal Encoding.find(encoding), bucket_data.encoding
    end
  end

  it "#read should return liquid as UTF-8 if no BOM is present" do
    utf_data = "something 星道ショップý"
    ascii_data = "something \xE6\x98\x9F\xE9\x81\x93\xE3\x82\xB7\xE3\x83\xA7\xE3\x83\x83\xE3\x83\x97\xC3\xBD"
    @cloud['assets/something.css.liquid'] = ascii_data
    data = @bucket.read('assets/something.css.liquid')
    assert_equal utf_data, data
    assert_equal Encoding::UTF_8, data.encoding
  end

  it "#read should return css as UTF-8 if no BOM is present" do
    utf_data = "something 星道ショップý"
    ascii_data = "something \xE6\x98\x9F\xE9\x81\x93\xE3\x82\xB7\xE3\x83\xA7\xE3\x83\x83\xE3\x83\x97\xC3\xBD"
    @cloud['assets/something.css'] = ascii_data
    data = @bucket.read('assets/something.css')
    assert_equal utf_data, data
    assert_equal Encoding::UTF_8, data.encoding
  end

  it "#read should return BINARY encoded data for anything that doesn't have a BOM and isn't liquid or css" do
    utf_data = "something \xC3\xBC"
    @cloud['assets/something.png'] = utf_data.force_encoding('BINARY')
    data = @bucket.read('assets/something.png')
    assert_equal utf_data.force_encoding('BINARY'), data
    assert_equal Encoding::ASCII_8BIT, data.encoding
  end

  it "#read should raise an exception when data is not ASCII-8BIT" do
    utf_data = "something \xC3\xBC"
    Rails.logger.expects(:warn).with("[PublicS3Bucket#encode_data] Expected data to be ASCII-8BIT but was UTF-8 for assets/something.txt")
    MockS3Interface::S3Object.any_instance.expects(:read).returns(utf_data.force_encoding('UTF-8'))
    data = @bucket.read('assets/something.txt')
    assert_equal Encoding::UTF_8, data.encoding
  end

  # this forces the encoding of the data string to ascii-8bit
  # just like the real s3 bucket object.
  class StubS3BucketObject
    def write(data, options)
      data.force_encoding("ASCII-8BIT")
    end
  end
end
