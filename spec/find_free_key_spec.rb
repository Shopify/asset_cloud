# frozen_string_literal: true

require "spec_helper"

class FindFreeKey
  extend AssetCloud::FreeKeyLocator
end

describe "FreeFilenameLocator", "when asked to return a free key such as the one passed in" do
  it "should simply return the key if it happens to be free" do
    expect(FindFreeKey).to(receive(:exist?).with("free.txt").and_return(false))

    expect(FindFreeKey.find_free_key_like("free.txt")).to(eq("free.txt"))
  end

  it "should append a UUID to the key before the extension if key is taken" do
    allow(SecureRandom).to(receive(:uuid).and_return("moo"))
    expect(FindFreeKey).to(receive(:exist?).with("free.txt").and_return(true))
    expect(FindFreeKey).to(receive(:exist?).with("free_moo.txt").and_return(false))

    expect(FindFreeKey.find_free_key_like("free.txt")).to(eq("free_moo.txt"))
  end

  it "should not strip any directory information from the key" do
    allow(SecureRandom).to(receive(:uuid).and_return("moo"))
    expect(FindFreeKey).to(receive(:exist?).with("products/images/image.gif").and_return(true))
    expect(FindFreeKey).to(receive(:exist?).with("products/images/image_moo.gif").and_return(false))

    expect(FindFreeKey.find_free_key_like("products/images/image.gif")).to(eq("products/images/image_moo.gif"))
  end

  it "should raise an exception if the randomly chosen value (after 10 attempts) is also taken" do
    allow(FindFreeKey).to(receive(:exist?).and_return(true))
    expect { FindFreeKey.find_free_key_like("free.txt") }.to(raise_error(StandardError))
  end

  it "should append a UUID to the key before the extensions if the force_uuid option is passed" do
    expect(FindFreeKey).to(receive(:exist?).with("free_as-in-beer.txt").and_return(false))
    allow(SecureRandom).to(receive(:uuid).and_return("as-in-beer"))

    expect(FindFreeKey.find_free_key_like("free.txt", force_uuid: true)).to(eq("free_as-in-beer.txt"))
  end
end
