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

  it "should parse an address with floor info and without city info" do
    addr = Normalic::Address.parse("201 Varick St. floor 12th")
    addr[:number].should == "201"
    addr[:street].should == "varick"
    addr[:type].should == "st"
  end

  it "should parse an address with no city info" do
    addr = Normalic::Address.parse("871 Washington Street")
    addr[:number].should == "871"
    addr[:street].should == "washington"
    addr[:type].should == "st"
  end


  it "should parse an address with direction info and no city info" do
    addr = Normalic::Address.parse("871 West Washington Street")
    addr[:number].should == "871"
    addr[:street].should == "washington"
    addr[:direction].should == "w"
    addr[:type].should == "st"
  end

  it "should use dot notation" do
    addr = Normalic::Address.parse("871 West Washington Street")
    addr.number.should == "871"
  end

  it "should return nil if a bad field is passed in" do
    addr = Normalic::Address.parse("871 West Washington Street")
    addr[:bad_name].should == nil
  end

  it "should return a line1" do
    addr = Normalic::Address.parse("871 West Washington Street")
    addr.line1.should == "871 W Washington St"
  end

  it "should have a to_s method" do
    addr = Normalic::Address.parse("167 West 4th Street, New York, NY 10014")
    addr.to_s.should == "167 W 4th St, New York, NY 10014"
  end
end
