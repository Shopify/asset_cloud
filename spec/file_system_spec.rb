# frozen_string_literal: true

require "spec_helper"
require "fileutils"

class FileSystemCloud < AssetCloud::Base
  bucket AssetCloud::InvalidBucket
  bucket :products, AssetCloud::FileSystemBucket
  bucket :tmp,      AssetCloud::FileSystemBucket
end

describe FileSystemCloud do
  directory = File.dirname(__FILE__) + "/files"

  before do
    @fs = FileSystemCloud.new(directory, "http://assets/files")
    FileUtils.mkdir_p(directory + "/tmp")
  end

  after do
    FileUtils.rm_rf(directory + "/tmp")
  end

  it "should use invalid bucket for random directories" do
    expect(@fs.bucket_for("does-not-exist/file.txt")).to(be_an_instance_of(AssetCloud::InvalidBucket))
  end

  it "should use filesystem bucket for products/ and tmp/  directories" do
    expect(@fs.bucket_for("products/file.txt")).to(be_an_instance_of(AssetCloud::FileSystemBucket))
    expect(@fs.bucket_for("tmp/file.txt")).to(be_an_instance_of(AssetCloud::FileSystemBucket))
  end

  it "should return Asset for existing files" do
    expect(@fs["products/key.txt"].exist?).to(eq(true))
    expect(@fs["products/key.txt"]).to(be_an_instance_of(AssetCloud::Asset))
  end

  it "should be able to test if a file exists or not" do
    expect(@fs.stat("products/key.txt").exist?).to(eq(true))
    expect(@fs.stat("products/key2.txt").exist?).to(eq(false))
  end

  it "should be able to list files" do
    expect(@fs.ls("products").collect(&:key)).to(eq(["products/key.txt"]))
  end

  describe "when modifying file system" do
    it "should call write after storing an asset" do
      expect(@fs.buckets[:tmp]).to(receive(:write).with("tmp/new_file.test", "hello world").and_return(true))

      @fs.build("tmp/new_file.test", "hello world").store
    end

    it "should be able to create new files" do
      @fs.build("tmp/new_file.test", "hello world").store

      expect(@fs.stat("tmp/new_file.test").exist).to(eq(true))
    end

    it "should be able to create new files with simple assignment" do
      @fs["tmp/new_file.test"] = "hello world"

      expect(@fs.stat("tmp/new_file.test").exist).to(eq(true))
    end

    it "should create directories as needed" do
      @fs.build("tmp/new_file.test", "hello world").store

      expect(@fs["tmp/new_file.test"].exist?).to(eq(true))
      expect(@fs["tmp/new_file.test"].value).to(eq("hello world"))
    end
  end
end
