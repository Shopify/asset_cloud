# frozen_string_literal: true

require "spec_helper"

class ValidatedAsset < AssetCloud::Asset
  validate :no_cats

  private

  def no_cats
    add_error("no cats allowed!") if value =~ /cat/i
    add_warning("bad dog!", "wet dog smell!") if value =~ /dog/i
  end
end

class BasicCloud < AssetCloud::Base
  bucket :dog_pound, AssetCloud::MemoryBucket, asset_class: ValidatedAsset
end

describe ValidatedAsset do
  before(:each) do
    @cloud = BasicCloud.new(File.dirname(__FILE__) + "/files", "http://assets/")
    @cat = @cloud.build("dog_pound/fido", "cat")
    @dog = @cloud.build("dog_pound/fido", "dog")
  end

  describe "#store" do
    it "should not store the asset unless validations pass" do
      expect(@cloud).to(receive(:write).with("dog_pound/fido", "dog").and_return(true))

      @cat.store
      expect(@cat.store).to(eq(false))
      expect(@cat.errors).to(eq(["no cats allowed!"]))
      expect(@dog.store).to(eq(true))
    end

    it "should store asset with warnings and save them in the warnings array" do
      expect(@dog.store).to(eq(true))
      expect(@dog.warnings).to(eq(["bad dog!", "wet dog smell!"]))
      expect(@cat.store).to(eq(false))
      expect(@cat.warnings).to(eq([]))
    end
  end

  describe "#store!" do
    it "should raise AssetNotFound with error message when validation fails" do
      expect { @cat.store! }.to(raise_error(AssetCloud::AssetNotSaved, "Validation failed: no cats allowed!"))
    end

    it "should return true when validations pass" do
      expect(@dog.store!).to(eq(true))
    end
  end

  describe "#valid?" do
    it "should clear errors, run validations, and return validity" do
      @cat.store
      expect(@cat.errors).to(eq(["no cats allowed!"]))
      expect(@cat.valid?).to(eq(false))
      expect(@cat.errors).to(eq(["no cats allowed!"]))
      @cat.value = "disguised feline"
      expect(@cat.valid?).to(eq(true))
      expect(@cat.errors).to(be_empty)
    end
  end
end
