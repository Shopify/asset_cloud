require 'spec_helper'

class VersionedMemoryCloud < AssetCloud::Base
  bucket :memory, AssetCloud::VersionedMemoryBucket
end

describe AssetCloud::VersionedMemoryBucket do
  directory = File.dirname(__FILE__) + '/files'

  before do
    @fs = VersionedMemoryCloud.new(directory , 'http://assets/files' )
    %w{one two three}.each do |content|
      @fs.write("memory/foo", content)
    end
  end

  describe '#versioned?' do
    it "should return true" do
      @fs.buckets[:memory].versioned?.should == true
    end
  end

  describe '#read_version' do
    it "should return the appropriate data when given a key and version" do
      @fs.read_version('memory/foo', 1).should == 'one'
      @fs.read_version('memory/foo', 3).should == 'three'
    end
  end

  describe '#versions' do
    it "should return a list of available version identifiers for the given key" do
      @fs.versions('memory/foo').should == [1,2,3]
    end
  end

end
