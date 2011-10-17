require 'lib/normalic'

describe "Normalic" do

  it "should parse an address with unit(floor) information" do
    addr = Normalic::Address.parse("201 Varick St. floor 12th, New York, NY 10014")
    addr[:number].should == "201"
    addr[:street].should == "Varick"
    addr[:direction].should == nil
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == false
  end

  it "should parse an address with direction information" do
    addr = Normalic::Address.parse("167 West 4th Street, New York, NY 10014")
    addr[:number].should == "167"
    addr[:street].should == "4th"
    addr[:direction].should == "W"
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == false
  end

  it "should parse an address with direction after the street type" do
    addr = Normalic::Address.parse("167 4th Street Northeast, New York, NY 10014")
    addr[:number].should == "167"
    addr[:street].should == "4th"
    addr[:direction].should == "NE"
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == false
  end

  it "should parse an intersection" do
    addr = Normalic::Address.parse("9th Ave. and W 13th St., New York, NY 10014")
    addr[:number].should == nil
    addr[:street].should == ["9th", "13th"]
    addr[:direction].should == [nil, "W"]
    addr[:type].should == ["Ave.", "St."]
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == true
  end

  it "should parse an address with incorrect state info" do
    addr = Normalic::Address.parse("871 Washington Street, New York, NewYork 10014")
    addr[:number].should == "871"
    addr[:street].should == "Washington"
    addr[:direction].should == nil
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == false
  end

  it "should normalize a zipcode with a +4 code" do
    addr = Normalic::Address.parse("201 Varick St., New York, NY 10014-1234")
    addr[:number].should == "201"
    addr[:street].should == "Varick"
    addr[:direction].should == nil
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == false
  end

  it "should parse an address with no city info" do
    addr = Normalic::Address.parse("871 Washington Street")
    addr[:number].should == "871"
    addr[:street].should == "Washington"
    addr[:direction].should == nil
    addr[:type].should == "St."
    addr[:city].should == nil
    addr[:state].should == nil
    addr[:zipcode].should == nil
    addr[:intersection].should == false
  end

  it "should parse an address with floor info and without city info" do
    addr = Normalic::Address.parse("201 Varick St. floor 12th")
    addr[:number].should == "201"
    addr[:street].should == "Varick"
    addr[:direction].should == nil
    addr[:type].should == "St."
    addr[:city].should == nil
    addr[:state].should == nil
    addr[:zipcode].should == nil
    addr[:intersection].should == false
  end

  it "should parse an address with direction info and no city info" do
    addr = Normalic::Address.parse("871 West Washington Street")
    addr[:number].should == "871"
    addr[:street].should == "Washington"
    addr[:direction].should == "W"
    addr[:type].should == "St."
    addr[:city].should == nil
    addr[:state].should == nil
    addr[:zipcode].should == nil
    addr[:intersection].should == false
  end

  it "should use dot notation" do
    addr = Normalic::Address.parse("871 west washington street, new york, ny 10014")
    addr.number.should == "871"
    addr.street.should == "Washington"
    addr.direction.should == "W"
    addr.type.should == "St."
    addr.city.should == "New York"
    addr.state.should == "NY"
    addr.zipcode.should == "10014"
    addr.intersection.should == false
  end

  it "should return nil if a bad field is passed in with index notation" do
    addr = Normalic::Address.parse("871 west washington street, new york, ny 10014")
    addr[:bad_name].should == nil
  end

  it "should return a line1" do
    addr = Normalic::Address.parse("871 West Washington Street")
    addr.line1.should == "871 W Washington St."
  end

  it "should have a to_s method" do
    addr = Normalic::Address.parse("167 West 4th Street, New York, NY 10014")
    addr.to_s.should == "167 W 4th St., New York, NY 10014"
  end
end
