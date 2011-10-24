require 'lib/normalic'


describe "Normalic::PhoneNumber" do

  it "should parse a bare phone number" do
    ph = Normalic::PhoneNumber.parse("2345678901")
    ph[:npa].should == "234"
    ph[:nxx].should == "567"
    ph[:slid].should == "8901"
  end

  it "should parse a phone number with an extension given" do
    ph = Normalic::PhoneNumber.parse("2345678901 ext. 555")
    ph[:npa].should == "234"
    ph[:nxx].should == "567"
    ph[:slid].should == "8901"
  end

  it "should parse a phone number with 1 in front" do
    ph = Normalic::PhoneNumber.parse("12345678901")
    ph[:npa].should == "234"
    ph[:nxx].should == "567"
    ph[:slid].should == "8901"
  end

  it "should parse a phone number with non-digit formatting" do
    ph = Normalic::PhoneNumber.parse("+1 (234) 567 - 8901")
    ph[:npa].should == "234"
    ph[:nxx].should == "567"
    ph[:slid].should == "8901"
  end

end


describe "Normalic::Address" do

  it "should parse an address with unit(floor) information" do
    addr = Normalic::Address.parse("201 Varick St. floor 12th, New York, NY 10014")
    addr[:number].should == "201"
    addr[:direction].should == nil
    addr[:street].should == "Varick"
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == false
  end

  it "should parse an address with direction information" do
    addr = Normalic::Address.parse("167 West 4th Street, New York, NY 10014")
    addr[:number].should == "167"
    addr[:direction].should == "W"
    addr[:street].should == "4th"
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == false
  end

  it "should parse an address with direction after the street type" do
    addr = Normalic::Address.parse("167 4th Street Northeast, New York, NY 10014")
    addr[:number].should == "167"
    addr[:direction].should == "NE"
    addr[:street].should == "4th"
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == false
  end

  it "should parse an intersection" do
    addr = Normalic::Address.parse("9th Ave. and W 13th St., New York, NY 10014")
    addr[:number].should == nil
    addr[:direction].should == [nil, "W"]
    addr[:street].should == ["9th", "13th"]
    addr[:type].should == ["Ave.", "St."]
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == true
  end

  it "should parse an address with incorrect state info and no zipcode" do
    addr = Normalic::Address.parse("871 Washington Street, New York, NewYork")
    addr[:number].should == "871"
    addr[:direction].should == nil
    addr[:street].should == "Washington"
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == nil
    addr[:intersection].should == false
  end

  it "should parse an address with no state info" do
    addr = Normalic::Address.parse("416 W 13th Street, New York, 10014")
    addr[:number].should == "416"
    addr[:direction].should == "W"
    addr[:street].should == "13th"
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == false
  end

  it "should parse only a zipcode into a state and city" do
    addr = Normalic::Address.parse("08848")
    addr[:number].should == nil
    addr[:direction].should == nil
    addr[:street].should == nil
    addr[:type].should == nil
    addr[:city].should == "Milford"
    addr[:state].should == "NJ"
    addr[:zipcode].should == "08848"
    addr[:intersection].should == false
  end

  it "should normalize a zipcode with a +4 code" do
    addr = Normalic::Address.parse("201 Varick St., New York, NY 10014-1234")
    addr[:number].should == "201"
    addr[:direction].should == nil
    addr[:street].should == "Varick"
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == false
  end

  it "should parse an address with no city info" do
    addr = Normalic::Address.parse("871 Washington Street")
    addr[:number].should == "871"
    addr[:direction].should == nil
    addr[:street].should == "Washington"
    addr[:type].should == "St."
    addr[:city].should == nil
    addr[:state].should == nil
    addr[:zipcode].should == nil
    addr[:intersection].should == false
  end

  it "should parse an address with floor info and without city info" do
    addr = Normalic::Address.parse("201 Varick St. floor 12th")
    addr[:number].should == "201"
    addr[:direction].should == nil
    addr[:street].should == "Varick"
    addr[:type].should == "St."
    addr[:city].should == nil
    addr[:state].should == nil
    addr[:zipcode].should == nil
    addr[:intersection].should == false
  end

  it "should parse an address with direction info and no city info" do
    addr = Normalic::Address.parse("871 West Washington Street")
    addr[:number].should == "871"
    addr[:direction].should == "W"
    addr[:street].should == "Washington"
    addr[:type].should == "St."
    addr[:city].should == nil
    addr[:state].should == nil
    addr[:zipcode].should == nil
    addr[:intersection].should == false
  end

  it "should use dot notation" do
    addr = Normalic::Address.parse("871 west washington street, new york, ny 10014")
    addr.number.should == "871"
    addr.direction.should == "W"
    addr.street.should == "Washington"
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
