require 'spec_helper'

MockRecords = Object.new

class MockActiveRecordBucket < AssetCloud::ActiveRecordBucket
  self.key_attribute = 'name'
  self.value_attribute = 'body'
  protected
  def records
    MockRecords
  end
end

class RecordCloud < AssetCloud::Base
  bucket :stuff, MockActiveRecordBucket
end

describe AssetCloud::ActiveRecordBucket do
  directory = File.dirname(__FILE__) + '/files'

  before do
    @cloud = RecordCloud.new(directory , 'http://assets/files' )
    @bucket = @cloud.buckets[:stuff]
  end

  describe '#ls' do
    before do
      MockRecords.should_receive(:connection).and_return(@mock_connection = double("connection"))
      @mock_connection.should_receive(:quote_column_name).with('name').and_return("`name`")
      (@mock_record = double("record")).should_receive(:name).and_return('stuff/a1')
    end

    it "should return a list of assets which start with the given prefix" do
      MockRecords.should_receive(:all).with(:conditions => ["`name` LIKE ?", "stuff/a%"]).and_return([@mock_record])

      @bucket.ls('stuff/a').size.should == 1
    end

    it "should return a list of all assets when a prefix is not given" do
      MockRecords.should_receive(:all).with(:conditions => ["`name` LIKE ?", "stuff%"]).and_return([@mock_record])

      @bucket.ls.size.should == 1
    end
  end

  describe '#read' do
    it "should return the value of a key when it exists" do
      (@mock_record = double("record")).should_receive(:body).and_return('foo')
      MockRecords.should_receive(:first).with(:conditions => {'name' => 'stuff/a1'}).and_return(@mock_record)

      @bucket.read('stuff/a1')
    end
    it "should raise AssetNotFoundError when nothing is there" do
      MockRecords.should_receive(:first).with(:conditions => {'name' => 'stuff/a1'}).and_return(nil)

      lambda {@bucket.read('stuff/a1')}.should raise_error(AssetCloud::AssetNotFoundError)
    end
  end

  describe '#write' do
    it "should write to the DB" do
      (@mock_record = double("record")).should_receive(:body=).with('foo').and_return('foo')
      @mock_record.should_receive(:save!).and_return(true)
      MockRecords.should_receive(:find_or_initialize_by_name).with('stuff/a1').and_return(@mock_record)

      @bucket.write('stuff/a1', 'foo')
    end
  end

  describe '#delete' do
    it "should destroy records" do
      (@mock_record = double("record")).should_receive(:destroy).and_return(true)
      MockRecords.should_receive(:first).with(:conditions => {'name' => 'stuff/a1'}).and_return(@mock_record)

      @bucket.delete('stuff/a1')
    end
  end

  describe '#stat' do
    it "should return appropriate metadata" do
      (@mock_record = double("record")).should_receive(:created_at).and_return(1982)
      @mock_record.should_receive(:updated_at).and_return(2002)
      @mock_record.should_receive(:body).and_return('foo')
      MockRecords.should_receive(:first).with(:conditions => {'name' => 'stuff/a1'}).and_return(@mock_record)

      metadata = @bucket.stat('stuff/a1')
      metadata.created_at.should == 1982
      metadata.updated_at.should == 2002
      metadata.size.should == 3
    end
  end



end
