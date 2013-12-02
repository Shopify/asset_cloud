require 'spec_helper'

class BlackholeCloud < AssetCloud::Base
  bucket AssetCloud::BlackholeBucket
end

describe BlackholeCloud do
  directory = File.dirname(__FILE__) + '/files'

  before do
    @fs = BlackholeCloud.new(directory , 'http://assets/files' )
  end

  it "should allow access to files using the [] operator" do
    @fs['tmp/image.jpg']
  end

  it "should return nil for non existent files" do
    @fs['tmp/image.jpg'].exist?.should == false
  end

  it "should still return nil, even if you wrote something there" do
    @fs['tmp/image.jpg'] = 'test'
    @fs['tmp/image.jpg'].exist?.should == false
  end

  describe "when using a sub path" do
    it "should allow access to files using the [] operator" do
      @fs['tmp/image.jpg']
    end

    it "should return nil for non existent files" do
      @fs['tmp/image.jpg'].exist?.should == false
    end

    it "should still return nil, even if you wrote something there" do
      @fs['tmp/image.jpg'] = 'test'
      @fs['tmp/image.jpg'].exist?.should == false
    end
  end
end
