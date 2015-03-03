require 'spec_helper'

describe AssetCloud::Bucket do
  before do
    @bucket = AssetCloud::Bucket.new(nil, nil)
  end

  describe "operations not supported" do
    it "#ls not supported" do
      expect { @bucket.ls('foo')}.to raise_error NotImplementedError
    end

    it "#read(key) not supported" do
      expect { @bucket.read('foo')}.to raise_error NotImplementedError
    end

    it "#write(key, data) not supported" do
      expect { @bucket.write('foo', 'bar')}.to raise_error NotImplementedError
    end

    it "#delete(key) not supported" do
      expect { @bucket.delete('foo')}.to raise_error NotImplementedError
    end
  end
end
