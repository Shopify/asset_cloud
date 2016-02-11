require 'spec_helper'

class SpecialAsset < AssetCloud::Asset
end

class LiquidAsset < AssetCloud::Asset
end

class BasicCloud < AssetCloud::Base
  bucket :special, AssetCloud::MemoryBucket, asset_class: SpecialAsset
  bucket :conditional, AssetCloud::MemoryBucket, asset_class: Proc.new {|key|
    LiquidAsset if key.ends_with?('.liquid')
  }
end

describe BasicCloud do
  directory = File.dirname(__FILE__) + '/files'

  before do
    @fs = BasicCloud.new(directory , 'http://assets/files' )
  end

  it "should raise invalid bucket if none is given" do
    @fs['image.jpg'].exist?.should == false
  end


  it "should be backed by a file system bucket" do
    @fs['products/key.txt'].exist?.should == true
  end

  it "should raise when listing non existing buckets" do
    @fs.ls('products').should == [AssetCloud::Asset.new(@fs, 'products/key.txt')]
  end


  it "should allow you to create new assets" do
    obj = @fs.build('new_file.test')
    obj.should be_an_instance_of(AssetCloud::Asset)
    obj.cloud.should be_an_instance_of(BasicCloud)
  end

  it "should raise error when using with minus relative or absolute paths" do
    lambda { @fs['../test']  }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['/test']    }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['.../test'] }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['./test']   }.should raise_error(AssetCloud::IllegalPath)
  end

  it "should raise error when filename has trailing period" do
    lambda { @fs['test.']             }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['/test/testfile.']   }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['test/directory/.']  }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['/test/testfile .']  }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['test/directory /.'] }.should raise_error(AssetCloud::IllegalPath)
  end

  it "should raise error when filename ends with space" do
    lambda { @fs['test ']             }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['/test/testfile ']   }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['test/directory/ ']  }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['test. ']            }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['/test/testfile. ']  }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['test/directory/. '] }.should raise_error(AssetCloud::IllegalPath)
  end

  it "should raise error when filename ends with slash" do
    lambda { @fs['test/']             }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['test/directory/']   }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['test /']            }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['/test/testfile /']  }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['test/directory//']  }.should raise_error(AssetCloud::IllegalPath)
  end

  it "should raise error when using with minus relative even after another directory" do
    lambda { @fs['test/../test']      }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['test/../../test']   }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['test/../../../test']}.should raise_error(AssetCloud::IllegalPath)
  end

  it "should raise an error when using names with combinations of '.' and ' '" do
    lambda { @fs['test. . . .. ... .. . ']   }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['test. .']   }.should raise_error(AssetCloud::IllegalPath)
    lambda { @fs['test.   .test2']   }.should raise_error(AssetCloud::IllegalPath)
  end

  it "should allow filenames with repeating dots" do
    @fs['test..jpg']
    @fs['assets/T.T..jpg']
    @fs['test/assets/1234123412341234_obj_description..14...58......v8...._2134123412341234.jpg']
  end

  it "should allow filenames with repeating underscores" do
    @fs['test__jpg']
    @fs['assets/T__T..jpg']
    @fs['test/assets/1234123412341234_obj_description..14...58......v8...__2134123412341234.jpg']
  end

  it "should allow filenames with various bracket arragements" do
    @fs['test[1].jpg']
    @fs['test[1]']
    @fs['[test].jpg']
  end

  it "should not raise an error when using directory names with spaces" do
    @fs['files/ass ets/.DS_Store']
  end

  it "should not raise_error when using unusual but valid filenames" do
    @fs['.DS_Store']
    @fs['photograph.g']
    @fs['_testfilename']
    @fs['assets/.DS_Store']
    @fs['assets/photograph.g']
    @fs['a/_testfilename']
    @fs['a']
  end

  it "should allow sensible relative filenames" do
    @fs['assets/rails_logo.gif']
    @fs['assets/rails_logo']
    @fs['assets/rails-2.gif']
    @fs['assets/223434.gif']
    @fs['files/1.JPG']
  end

  it "should compute complete urls to assets" do
    @fs.url_for('products/key with spaces.txt').should == 'http://assets/files/products/key%20with%20spaces.txt'
  end

  describe "#find" do
    it "should return the appropriate asset when one exists" do
      asset = @fs.find('products/key.txt')
      asset.key.should == 'products/key.txt'
      asset.value.should == 'value'
    end
    it "should raise AssetNotFoundError when the asset doesn't exist" do
      lambda { @fs.find('products/not-there.txt') }.should raise_error(AssetCloud::AssetNotFoundError)
    end
  end

  describe "#[]" do
    it "should return the appropriate asset when one exists" do
      asset = @fs['products/key.txt']
      asset.key.should == 'products/key.txt'
      asset.value.should == 'value'
    end
    it "should not raise any errors when the asset doesn't exist" do
      lambda { @fs['products/not-there.txt'] }.should_not raise_error
    end
  end

  describe "#move" do
    it "should return move a resource" do
      asset = @fs['products/key.txt']
      asset.key.should == 'products/key.txt'
      asset.value.should == 'value'
      @fs.move('products/key.txt', 'products/key2.txt')
      new_asset = @fs['products/key2.txt']
      new_asset.key.should == 'products/key2.txt'
      new_asset.value.should == 'value'
      expect {@fs['products/key.txt'].value }.to raise_error(AssetCloud::AssetNotFoundError)
      @fs.move('products/key2.txt', 'products/key.txt')
    end
  end

  describe "#[]=" do
    it "should write through the Asset object (and thus run any callbacks on the asset)" do
      special_asset = double(:special_asset)
      special_asset.should_receive(:value=).with('fancy fancy!')
      special_asset.should_receive(:store)
      SpecialAsset.should_receive(:at).and_return(special_asset)
      @fs['special/fancy.txt'] = 'fancy fancy!'
    end
  end

  describe "#bucket" do
    it "should allow specifying a class to use for assets in this bucket" do
      @fs['assets/rails_logo.gif'].should be_instance_of(AssetCloud::Asset)
      @fs['special/fancy.txt'].should be_instance_of(SpecialAsset)

      @fs.build('assets/foo').should be_instance_of(AssetCloud::Asset)
      @fs.build('special/foo').should be_instance_of(SpecialAsset)
    end

    it "should allow specifying a proc that determines the class to use, using the default bucket when returning nil" do
      @fs.build('conditional/default.js').should be_instance_of(AssetCloud::Asset)
      @fs.build('conditional/better.liquid').should be_instance_of(LiquidAsset)
    end

    it "should raise " do
      expect { BasicCloud.bucket(AssetCloud::MemoryBucket, asset_class: Proc.new {}) }.to(raise_error(ArgumentError))
    end
  end

  describe "MATCH_BUCKET" do
    it "should match following stuff " do

      'products/key.txt' =~ AssetCloud::Base::MATCH_BUCKET
      $1.should == 'products'

      'products/subpath/key.txt' =~ AssetCloud::Base::MATCH_BUCKET
      $1.should == 'products'

      'key.txt' =~ AssetCloud::Base::MATCH_BUCKET
      $1.should == nil

      'products' =~ AssetCloud::Base::MATCH_BUCKET
      $1.should == 'products'
    end
  end
end
