require File.join(File.dirname(__FILE__), '..', 'lib', 'normalic')


describe "Normalic::URI" do

  it "should parse a well-formatted URI" do
    uri = Normalic::URI.parse("http://mike@mkscrg.github.com:80/about.html?lang=ruby&dvcs=git#blog")
    uri[:scheme].should == "http"
    uri[:user].should == "mike"
    uri[:subdomain].should == "mkscrg"
    uri[:domain].should == "github"
    uri[:tld].should == "com"
    uri[:port].should == "80"
    uri[:path].should == "/about.html"
    uri[:query_hash].should == {"lang" => "ruby", "dvcs" => "git"}
    uri[:fragment].should == "blog"
  end

  it "should print a parsed URI correctly" do
    uri = Normalic::URI.parse("http://mike@mkscrg.github.com:80/about.html?lang=ruby&dvcs=git#blog")
    ["http://mike@mkscrg.github.com:80/about.html?lang=ruby&dvcs=git#blog",
     "http://mike@mkscrg.github.com:80/about.html?dvcs=git&lang=ruby#blog"].include?(uri.to_s.should)
  end

  it "should parse a bare domain and tld with default scheme and subdomain" do
    uri = Normalic::URI.parse("github.com")
    uri[:scheme].should == "http"
    uri[:user].should == nil
    uri[:subdomain].should == "www"
    uri[:domain].should == "github"
    uri[:tld].should == "com"
    uri[:port].should == nil
    uri[:path].should == "/"
    uri[:query_hash].should == nil
    uri[:fragment].should == nil
  end

  it "should parse a bare domain containing dashes" do
    uri = Normalic::URI.parse("web-stuff.com")
    uri.should_not be_nil
    uri[:scheme].should == "http"
    uri[:user].should == nil
    uri[:subdomain].should == "www"
    uri[:domain].should == "web-stuff"
    uri[:tld].should == "com"
    uri[:port].should == nil
    uri[:path].should == "/"
    uri[:query_hash].should == nil
    uri[:fragment].should == nil
  end

  it "should normalize consecutive slashes and strip trailing slashes in the path" do
    uri = Normalic::URI.parse("https://github.com/mkscrg//normalic/")
    uri[:scheme].should == "https"
    uri[:user].should == nil
    uri[:subdomain].should == "www"
    uri[:domain].should == "github"
    uri[:tld].should == "com"
    uri[:port].should == nil
    uri[:path].should == "/mkscrg/normalic"
    uri[:query_hash].should == nil
    uri[:fragment].should == nil
  end

  it "should normalize relative path segments: '.' and '..'" do
    uri = Normalic::URI.parse("github.com/ericxtang/expresso/../normalic")
    uri[:scheme].should == "http"
    uri[:user].should == nil
    uri[:subdomain].should == "www"
    uri[:domain].should == "github"
    uri[:tld].should == "com"
    uri[:port].should == nil
    uri[:path].should == "/ericxtang/normalic"
    uri[:query_hash].should == nil
    uri[:fragment].should == nil
  end

  it "should match_essential? a nil subdomain against a 'www' subdomain" do
    uri1 = Normalic::URI.parse("http://www.github.com")
    uri2 = Normalic::URI.parse("http://github.com")
    uri1.match_essential?(uri2).should == true
  end

  it "should match_essential? using the subdomain, domain, and tld" do
    uri1 = Normalic::URI.parse("http://www.hyperpublic.com")
    uri2 = Normalic::URI.parse("http://oxcart.hyperpublic.com")
    uri1.match_essential?(uri2).should == false
  end

  it "should match_essential? using ONLY the subdomain, domain, and tld" do
    uri1 = Normalic::URI.parse("http://www.hyperpublic.com/placesplus")
    uri2 = Normalic::URI.parse("http://www.hyperpublic.com/deals")
    uri1.match_essential?(uri2).should == true
  end

  it "should be nondestructive" do
    raw = "github.com"
    raw_orig = raw.clone
    uri = Normalic::URI.parse(raw)
    raw_orig.should == raw
    uri[:scheme].should == "http"
    uri[:user].should == nil
    uri[:subdomain].should == "www"
    uri[:domain].should == "github"
    uri[:tld].should == "com"
    uri[:port].should == nil
    uri[:path].should == "/"
    uri[:query_hash].should == nil
    uri[:fragment].should == nil
  end

end


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

  it "should be nondestructive" do
    raw = "2345678901"
    raw_orig = raw.clone
    ph = Normalic::PhoneNumber.parse(raw)
    raw_orig.should == raw
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

  it "should normalize a canadian address" do
    addr = Normalic::Address.parse("800 Reynolds Dr, Kincardine, ON N2Z 3A5")
    addr[:number].should == "800"
    addr[:direction].should == nil
    addr[:street].should == "Reynolds"
    addr[:type].should == "Dr."
    addr[:city].should == "Kincardine"
    addr[:state].should == "ON"
    addr[:zipcode].should == "N2Z 3A5"
    addr[:intersection].should == false
  end

  it "should normalize a canadian address with unspaced postal code" do
    addr = Normalic::Address.parse("800 Reynolds Dr, Kincardine, ON N2Z3A5")
    addr[:number].should == "800"
    addr[:direction].should == nil
    addr[:street].should == "Reynolds"
    addr[:type].should == "Dr."
    addr[:city].should == "Kincardine"
    addr[:state].should == "ON"
    addr[:zipcode].should == "N2Z 3A5"
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

  it "should parse an address from a hash of fields" do
    addr = Normalic::Address.normalize_fields(:number => 201,
                                              :street => "Varick",
                                              "type" => "St.",
                                              :city => "New York",
                                              :state => "NY",
                                              "zipcode" => 10014)
    addr[:number].should == "201"
    addr[:direction].should == nil
    addr[:street].should == "Varick"
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == false
  end

  it "should parse an address from a hash of fields including 'address'" do
    addr = Normalic::Address.normalize_fields("address" => "201 Varick St.",
                                              :city => "New York",
                                              :state => "NY",
                                              :zipcode => 10014)
    addr[:number].should == "201"
    addr[:direction].should == nil
    addr[:street].should == "Varick"
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == false
  end

  it "should parse an address from a hash of fields including 'address_line1'" do
    addr = Normalic::Address.normalize_fields("address_line1" => "201 Varick St.",
                                              :city => "New York",
                                              :state => "NY",
                                              :zipcode => 10014)
    addr[:number].should == "201"
    addr[:direction].should == nil
    addr[:street].should == "Varick"
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
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

  it "should be nondestructive" do
    raw = "167 West 4th Street, New York, NY 10014"
    raw_orig = raw.clone
    addr = Normalic::Address.parse(raw)
    raw_orig.should == raw
    addr[:number].should == "167"
    addr[:direction].should == "W"
    addr[:street].should == "4th"
    addr[:type].should == "St."
    addr[:city].should == "New York"
    addr[:state].should == "NY"
    addr[:zipcode].should == "10014"
    addr[:intersection].should == false
  end

end
