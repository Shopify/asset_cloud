# frozen_string_literal: true

require "spec_helper"

class AfterStoreCallback
  class << self
    def after_store(*args); end
  end
end

class CallbackAsset < AssetCloud::Asset
  before_store :callback_before_store
  before_delete :callback_before_delete
  after_delete :callback_after_delete
  before_validate :make_value_valid
  after_validate :add_spice
  validate :valid_value

  before_validate(&:proc_executed_before)
  after_validate(&:proc_executed_after)

  after_store ::AfterStoreCallback

  def proc_executed_before(*args); end
  def proc_executed_after(*args); end

  private

  def callback_before_delete(*args); end

  def make_value_valid
    self.value = "valid"
  end

  def add_spice
    self.value += " spice"
  end

  def valid_value
    add_error('value is not "valid"') unless value == "valid"
  end
end

class BasicCloud < AssetCloud::Base
  bucket :callback_assets, AssetCloud::MemoryBucket, asset_class: CallbackAsset
end

class CallbackCloud < AssetCloud::Base
  bucket :tmp, AssetCloud::MemoryBucket

  after_delete :callback_after_delete
  before_delete :callback_before_delete

  after_write :callback_after_write
  before_write :callback_before_write

  def callback_before_write(*args); end

  def callback_after_write(*args); end
end

class MethodRecordingCloud < AssetCloud::Base
  attr_accessor :run_callbacks

  bucket :tmp, AssetCloud::MemoryBucket

  before_write :callback_before_write
  after_write :callback_before_write

  def callback_before_write(*)
    @run_callbacks << __method__
  end
end

describe CallbackCloud do
  before do
    @fs = CallbackCloud.new(File.dirname(__FILE__) + "/files", "http://assets/")
    @fs.write("tmp/file.txt", "foo")
  end

  it "should invoke callbacks after store" do
    expect(@fs).to(receive(:callback_before_write).with("tmp/file.txt", "text").and_return(true))
    expect(@fs).to(receive(:callback_after_write).with("tmp/file.txt", "text").and_return(true))

    expect(@fs.write("tmp/file.txt", "text")).to(eq(true))
    expect(@fs.read("tmp/file.txt")).to(eq("text"))
  end

  it "should invoke callbacks after delete" do
    expect(@fs).to(receive(:callback_before_delete).with("tmp/file.txt").and_return(true))
    expect(@fs).to(receive(:callback_after_delete).with("tmp/file.txt").and_return(true))

    expect(@fs.delete("tmp/file.txt")).to(eq("foo"))
  end

  it "should not invoke other callbacks when a before_ filter returns false" do
    expect(@fs).to(receive(:callback_before_delete)
      .with("tmp/file.txt")
      .and_return(false))
    expect(@fs).not_to(receive(:callback_after_delete))

    expect(@fs.delete("tmp/file.txt")).to(eq(nil))
  end

  it "should invoke callbacks even when constructing a new asset" do
    expect(@fs).to(receive(:callback_before_write).with("tmp/file.txt", "hello").and_return(true))
    expect(@fs).to(receive(:callback_after_write).with("tmp/file.txt", "hello").and_return(true))

    asset = @fs.build("tmp/file.txt")
    asset.value = "hello"
    expect(asset.store).to(eq(true))
  end
end

describe MethodRecordingCloud do
  before do
    @fs = MethodRecordingCloud.new(File.dirname(__FILE__) + "/files", "http://assets/")
    @fs.run_callbacks = []
  end

  it "should record event when invoked" do
    @fs.write("tmp/file.txt", "random data")
    expect(@fs.run_callbacks).to(eq([:callback_before_write, :callback_before_write]))
  end

  it "should record event when assignment operator is used" do
    @fs["tmp/file.txt"] = "random data"
    expect(@fs.run_callbacks).to(eq([:callback_before_write, :callback_before_write]))
  end
end

describe CallbackAsset do
  before(:each) do
    @fs = BasicCloud.new(File.dirname(__FILE__) + "/files", "http://assets/")
    @fs.write("callback_assets/foo", "bar")
    @asset = @fs.asset_at("callback_assets/foo")
  end

  it "should run before_validate, then validate, then after validate, then before_store, then store" do
    expect(@asset).to(receive(:callback_before_store).and_return(true))
    expect(@asset).not_to(receive(:callback_after_delete))

    @asset.value = "foo"
    expect(@asset.store).to(eq(true))
    expect(@asset.value).to(eq("valid spice"))
  end

  it "should run before_validate with procs" do
    expect(@asset).to(receive(:callback_before_store).and_return(true))
    expect(@asset).to(receive(:proc_executed_before))

    @asset.value = "foo"

    expect(@asset.store).to(eq(true))
  end

  it "should run after_validate with procs" do
    expect(@asset).to(receive(:callback_before_store).and_return(true))
    expect(@asset).to(receive(:proc_executed_after))

    @asset.value = "foo"

    expect(@asset.store).to(eq(true))
  end

  it "should run its after_delete callback after delete is called" do
    expect(@asset).not_to(receive(:callback_before_store))
    expect(@asset).to(receive(:callback_after_delete).and_return(true))

    expect(@asset.delete).to(eq("bar"))
  end

  it "not invoke other callbacks when a before_ filter returns false" do
    expect(@asset).to(receive(:callback_before_delete).and_return(false))
    expect(@asset).not_to(receive(:callback_after_delete))

    expect(@asset.delete).to(eq(nil))
  end

  it "should invoke after_store callback defined in separate class" do
    local_fs = BasicCloud.new(File.dirname(__FILE__) + "/files", "http://assets/")
    local_fs.write("callback_assets/foo", "bar")
    local_asset = local_fs.asset_at("callback_assets/foo")

    expect(local_asset).to(receive(:callback_before_store).and_return(true))
    expect(AfterStoreCallback).to(receive(:after_store))

    expect(local_asset.store).to(eq(true))
  end
end
