describe Regexp do
  
  before { @regexp = /^(\w+)(\/|$)/ }
  
  it "should match following stuff " do
    
    'products/key.txt' =~ @regexp
    $1.should == 'products'

    'products/subpath/key.txt' =~ @regexp
    $1.should == 'products'
    
    'key.txt' =~ @regexp
    $1.should == nil
    
    'products' =~ @regexp
    $1.should == 'products'
    
  end
end