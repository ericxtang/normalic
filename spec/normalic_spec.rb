require 'lib/normalic'

describe "Normalic test" do
  
  it "should parse an address with unit(floor) information" do
    addr = Normalic::Address.parse("201 Varick St. floor 12th, New York, NY 10014")
    addr[:number].should == "201"
    addr[:street].should == "varick"
    addr[:type].should == "st"
    addr[:city].should == "new york"
    addr[:state].should == "ny"
    addr[:zipcode].should == "10014"
  end

  it "should parse an address with direction information" do
    addr = Normalic::Address.parse("167 West 4th Street, New York, NY 10014")
    addr[:number].should == "167"
    addr[:street].should == "4th"
    addr[:direction].should == "w"
    addr[:type].should == "st"
    addr[:city].should == "new york"
    addr[:state].should == "ny"
    addr[:zipcode].should == "10014"
  end

  it "should parse an address with incorrect state info" do
    addr = Normalic::Address.parse("871 Washington Street, New York, NewYork 10014")
    addr[:number].should == "871"
    addr[:street].should == "washington"
    addr[:type].should == "st"
    addr[:city].should == "new york"
    addr[:state].should == "ny"
    addr[:zipcode].should == "10014"
  end

end
