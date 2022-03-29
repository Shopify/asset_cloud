# frozen_string_literal: true

require "spec_helper"

MockRecords = Object.new

class MockActiveRecordBucket < AssetCloud::ActiveRecordBucket
  self.key_attribute = "name"
  self.value_attribute = "body"

  protected

  def records
    MockRecords
  end
end

class RecordCloud < AssetCloud::Base
  bucket :stuff, MockActiveRecordBucket
end

describe AssetCloud::ActiveRecordBucket do
  directory = File.dirname(__FILE__) + "/files"

  before do
    @cloud = RecordCloud.new(directory, "http://assets/files")
    @bucket = @cloud.buckets[:stuff]
  end

  describe "#ls" do
    before do
      expect(MockRecords).to(receive(:connection).and_return(@mock_connection = double("connection")))
      expect(@mock_connection).to(receive(:quote_column_name).with("name").and_return("`name`"))
      expect(@mock_record = double("record")).to(receive(:name).and_return("stuff/a1"))
    end

    it "should return a list of assets which start with the given prefix" do
      expect(MockRecords).to(receive(:all).with(conditions: ["`name` LIKE ?", "stuff/a%"]).and_return([@mock_record]))

      expect(@bucket.ls("stuff/a").size).to(eq(1))
    end

    it "should return a list of all assets when a prefix is not given" do
      expect(MockRecords).to(receive(:all).with(conditions: ["`name` LIKE ?", "stuff%"]).and_return([@mock_record]))

      expect(@bucket.ls.size).to(eq(1))
    end
  end

  describe "#read" do
    it "should return the value of a key when it exists" do
      expect(@mock_record = double("record")).to(receive(:body).and_return("foo"))
      expect(MockRecords).to(receive(:first).with(conditions: { "name" => "stuff/a1" }).and_return(@mock_record))

      @bucket.read("stuff/a1")
    end
    it "should raise AssetNotFoundError when nothing is there" do
      expect(MockRecords).to(receive(:first).with(conditions: { "name" => "stuff/a1" }).and_return(nil))

      expect { @bucket.read("stuff/a1") }.to(raise_error(AssetCloud::AssetNotFoundError))
    end
  end

  describe "#write" do
    it "should write to the DB" do
      expect(@mock_record = double("record")).to(receive(:body=).with("foo").and_return("foo"))
      expect(@mock_record).to(receive(:save!).and_return(true))
      expect(MockRecords).to(receive(:find_or_initialize_by_name).with("stuff/a1").and_return(@mock_record))

      @bucket.write("stuff/a1", "foo")
    end
  end

  describe "#delete" do
    it "should destroy records" do
      expect(@mock_record = double("record")).to(receive(:destroy).and_return(true))
      expect(MockRecords).to(receive(:first).with(conditions: { "name" => "stuff/a1" }).and_return(@mock_record))

      @bucket.delete("stuff/a1")
    end
  end

  describe "#stat" do
    it "should return appropriate metadata" do
      expect(@mock_record = double("record")).to(receive(:created_at).and_return(1982))
      expect(@mock_record).to(receive(:updated_at).and_return(2002))
      expect(@mock_record).to(receive(:body).and_return("foo"))
      expect(MockRecords).to(receive(:first).with(conditions: { "name" => "stuff/a1" }).and_return(@mock_record))

      metadata = @bucket.stat("stuff/a1")
      expect(metadata.created_at).to(eq(1982))
      expect(metadata.updated_at).to(eq(2002))
      expect(metadata.size).to(eq(3))
    end
  end
end
