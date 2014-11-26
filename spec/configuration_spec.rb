require 'spec_helper'

describe AssetCloud::Configuration do
  after(:each) do
    AssetCloud::S3Bucket.reset_config
  end

  describe "sets and resets configuration" do
    it "#configure sets s3 values" do
      mock_interface = MockS3Interface.new('a', 'b')
      AssetCloud::S3Bucket.configure do |config|
        config.aws_s3_connection = mock_interface
        config.s3_bucket_name = 'asset-cloud-test'
      end

     AssetCloud::S3Bucket.s3_bucket.should == mock_interface.buckets['asset-cloud-test']
    end

    it "#reset configuration nulls out s3 values" do
      AssetCloud::S3Bucket.configure do |config|
        config.aws_s3_connection = MockS3Interface.new('a', 'b')
        config.s3_bucket_name = 'asset-cloud-test'
      end
      AssetCloud::S3Bucket.reset_config

      AssetCloud::S3Bucket.aws_s3_connection.should be nil
      AssetCloud::S3Bucket.s3_bucket_name be nil
      AssetCloud::S3Bucket.aws_access_key_id.should be nil
      AssetCloud::S3Bucket.aws_secret_access_key.should be nil
      AssetCloud::S3Bucket.use_ssl.should be nil
      AssetCloud::S3Bucket.aws_open_timeout.should be nil
      AssetCloud::S3Bucket.aws_read_timeout.should be nil
    end
  end
end
