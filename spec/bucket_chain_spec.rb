# frozen_string_literal: true

require "spec_helper"

class ChainedCloud < AssetCloud::Base
  bucket :stuff, AssetCloud::BucketChain.chain(
    AssetCloud::MemoryBucket,
    AssetCloud::MemoryBucket,
    AssetCloud::FileSystemBucket,
  )

  bucket :versioned_stuff, AssetCloud::BucketChain.chain(
    AssetCloud::FileSystemBucket,
    AssetCloud::VersionedMemoryBucket,
    AssetCloud::MemoryBucket,
  )
end

describe AssetCloud::BucketChain do
  directory = File.dirname(__FILE__) + "/files"

  before(:each) do
    @cloud = ChainedCloud.new(directory, "http://assets/files")
    @bucket_chain = @cloud.buckets[:stuff]
    @chained_buckets = @bucket_chain.chained_buckets
    @chained_buckets.each { |b| b.ls("stuff").each(&:delete) }

    @versioned_stuff = @cloud.buckets[:versioned_stuff]
  end

  describe ".chain" do
    it "should take multiple Bucket classes and return a new Bucket class" do
      expect(@bucket_chain).to(be_a_kind_of(AssetCloud::BucketChain))
    end
  end

  describe "#write" do
    it "should write to each sub-bucket when everything is kosher and return the result of the first write" do
      @chained_buckets.each do |bucket|
        expect(bucket).to(receive(:write).with("stuff/foo", "successful creation").and_return("successful creation"))
      end

      expect(@bucket_chain.write("stuff/foo", "successful creation")).to(eq("successful creation"))
    end
    it "should roll back creation-writes and re-raise an error when a bucket raises one" do
      expect(@chained_buckets.last).to(receive(:write).with("stuff/foo", "unsuccessful creation").and_raise("hell"))
      @chained_buckets[0..-2].each do |bucket|
        expect(bucket).to(receive(:write).with("stuff/foo", "unsuccessful creation").and_return(true))
        expect(bucket).to(receive(:delete).with("stuff/foo").and_return(true))
      end

      expect { @bucket_chain.write("stuff/foo", "unsuccessful creation") }.to(raise_error(RuntimeError))
    end
    it "should roll back update-writes and re-raise an error when a bucket raises one" do
      @bucket_chain.write("stuff/foo", "original value")

      expect(@chained_buckets.last).to(receive(:write).with("stuff/foo", "new value").and_raise("hell"))

      expect { @bucket_chain.write("stuff/foo", "new value") }.to(raise_error(RuntimeError))
      @chained_buckets.each do |bucket|
        expect(bucket.read("stuff/foo")).to(eq("original value"))
      end
    end
  end

  describe "#delete" do
    it "should delete from each sub-bucket when everything is kosher" do
      @bucket_chain.write("stuff/foo", "successful deletion comin' up")

      @chained_buckets.each do |bucket|
        expect(bucket).to(receive(:delete).with("stuff/foo").and_return(true))
      end

      @bucket_chain.delete("stuff/foo")
    end
    it "should roll back deletions and re-raise an error when a bucket raises one" do
      @bucket_chain.write("stuff/foo", "this deletion will fail")

      expect(@chained_buckets.last).to(receive(:delete).with("stuff/foo").and_raise("hell"))
      @chained_buckets[0..-2].each do |bucket|
        expect(bucket).to(receive(:delete).with("stuff/foo").and_return(true))
        expect(bucket).to(receive(:write).with("stuff/foo", "this deletion will fail").and_return(true))
      end

      expect { @bucket_chain.delete("stuff/foo") }.to(raise_error(RuntimeError))
    end
  end

  describe "#read" do
    it "should read from only the first available sub-bucket" do
      expect(@chained_buckets[0]).to(receive(:read).with("stuff/foo").and_raise(NotImplementedError))
      expect(@chained_buckets[0]).to(receive(:ls).with(nil).and_raise(NoMethodError))
      expect(@chained_buckets[0]).to(receive(:stat).and_return(:metadata))

      expect(@chained_buckets[1]).to(receive(:read).with("stuff/foo").and_return("bar"))
      expect(@chained_buckets[1]).to(receive(:ls).with(nil).and_return(:some_assets))
      expect(@chained_buckets[1]).not_to(receive(:stat))

      @chained_buckets[2..-1].each do |bucket|
        expect(bucket).not_to(receive(:read))
        expect(bucket).not_to(receive(:ls))
        expect(bucket).not_to(receive(:stat))
      end

      expect(@bucket_chain.read("stuff/foo")).to(eq("bar"))
      expect(@bucket_chain.ls).to(eq(:some_assets))
      expect(@bucket_chain.stat).to(eq(:metadata))
    end
  end

  describe "#read_version" do
    it "should read from only the first available sub-bucket" do
      buckets = @versioned_stuff.chained_buckets

      expect(buckets[1]).to(receive(:read_version).with("stuff/foo", 3).and_return("bar"))
      expect(buckets.last).not_to(receive(:read_version))

      expect(@versioned_stuff.read_version("stuff/foo", 3)).to(eq("bar"))
    end
  end

  describe "#versions" do
    it "should read from only the first available sub-bucket" do
      buckets = @versioned_stuff.chained_buckets

      expect(buckets[1]).to(receive(:versions).with("versioned_stuff/foo").and_return([1, 2, 3]))
      expect(buckets.last).not_to(receive(:versions))

      expect(@versioned_stuff.versions("versioned_stuff/foo")).to(eq([1, 2, 3]))
    end
  end

  describe "with versioned buckets" do
    it "should store and retrieve versions seamlessly" do
      ["one", "two", "three"].each do |content|
        @cloud["versioned_stuff/foo"] = content
      end
      asset = @cloud["versioned_stuff/foo"]
      expect(asset.value).to(eq("three"))
      expect(asset.rollback(1).value).to(eq("one"))
      expect(asset.versions).to(eq([1, 2, 3]))
      asset.value = "four"
      asset.store
      expect(asset.versions).to(eq([1, 2, 3, 4]))
    end
  end

  describe "#respond_to?" do
    it "should return true if any chained buckets respond to the given method" do
      expect(@bucket_chain.respond_to?(:foo)).to(eq(false))
      expect(@chained_buckets[1]).to(receive(:respond_to?).with(:bar).and_return(true))
      expect(@bucket_chain.respond_to?(:bar)).to(eq(true))
    end
  end

  describe "#method_missing" do
    it "should try each bucket" do
      expect(@chained_buckets[1]).to(receive(:buzz).and_return(true))
      expect(@chained_buckets[2]).not_to(receive(:buzz))
      expect(@bucket_chain.buzz).to(eq(true))
    end
  end
end
