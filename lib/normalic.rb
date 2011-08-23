#only handles U.S addresses
require 'constants'

module Normalic
  class Address

    attr_accessor :number, :direction, :street, :type, :city, :state, :zipcode

    def initialize(fields={})
      @number = fields[:number]
      @direction = fields[:direction]
      @street = fields[:street]
      @type = fields[:type]
      @city = fields[:city]
      @state = fields[:state]
      @zipcode = fields[:zipcode]
    end

    def self.titlize(str)
      if str
        str.gsub(/\w+/){|w| w.capitalize}
      else
        nil
      end
    end

    def [](field_name)
      begin
        self.send(field_name.to_s)
      rescue NoMethodError => e
        nil
      end
    end

    def []=(field_name, value)
      begin
        self.send("#{field_name}=", value)
      rescue NoMethodError => e
        nil
      end
    end

    def to_s
      #"#{line1},#{" #{city.gsub(/\w+/){|w| w.capitalize}}," if city}#{" #{state.upcase}" if state}#{" " + zipcode if zipcode}".strip
      "#{line1}#{", #{city}" if city}#{", #{state}" if state}#{" " + zipcode if zipcode}".strip
      #"#{line1}, #{city}, #{state} #{zipcode}"
    end

    def line1
      #"#{number}#{" " + direction.upcase if direction}#{" " + street.gsub(/\w+/){|w| w.capitalize} if street}#{" " + type.capitalize if type}".strip
      "#{number}#{" " + direction if direction}#{" " + street if street}#{" " + type if type}"
    end

    #Iteratively take chunks off of the string.
    def self.parse(address)
      address.strip!
      regex = {
        :unit => /(((\#?\w*)?\W*(su?i?te|p\W*[om]\W*b(?:ox)?|dept|department|ro*m|floor|fl|apt|apartment|unit|box))$)|(\W((su?i?te|p\W*[om]\W*b(?:ox)?|dept|department|ro*m|floor|fl|apt|apartment|unit|box)\W*(\#?\w*)?)\W{0,3}$)/i,
        :direct => Regexp.new(Directional.keys * '|' + '|' + Directional.values * '\.?|',Regexp::IGNORECASE),
        :type => Regexp.new('(' + StreetTypes_list * '|' + ')\\W*?$',Regexp::IGNORECASE),
        :number => /\d+-?\d*/,
        :fraction => /\d+\/\d+/,
        :country => /\W+USA$/,
        :zipcode => /\W+(\d{5}|\d{5}-\d{4})$/,
        :state => Regexp.new('\W+(' + StateCodes.values * '|' + '|' + StateCodes.keys * '|' + ')$',Regexp::IGNORECASE),
      }
      regex[:street] = Regexp.new('((' + regex[:direct].source + ')\\W)?\\W*(.*)\\W*(' + regex[:type].source + ')?', Regexp::IGNORECASE)

      #get rid of USA at the end
      country_code = address[regex[:country]] and address.gsub!(regex[:country], "")
      zipcode = address[regex[:zipcode]] and address.gsub!(regex[:zipcode], "")
      zipcode.gsub!(/\W/, "") if zipcode

      state = address[regex[:state]] and address.gsub!(regex[:state], "")
      state.gsub!(/(^\W*|\W*$)/, "").downcase! if state
      state = StateCodes[state] || state and state.downcase!

      if ZipCityMap[zipcode]
        regex[:city] = Regexp.new("\\W+" + ZipCityMap[zipcode] + "$", Regexp::IGNORECASE)
        regex[:city] = /,.*$/ if !address[regex[:city]]
        city = ZipCityMap[zipcode]
      else
        regex[:city] = /,.*$/
        city = address[regex[:city]] 
        city.gsub!(/(^\W*|\W*$)/, "").downcase! if city
      end

      address.gsub!(regex[:city], "")
      address.gsub!(regex[:unit], "")
      address.gsub!(Regexp.new('\W(' + regex[:direct].source + ')\\W{0,3}$', Regexp::IGNORECASE), "")

      type = address[regex[:type]] and address.gsub!(regex[:type], "")
      type.gsub!(/(^\W*|\W*$)/, "").downcase! if type
      type = StreetTypes[type] || type if type

      if address =~ /(\Wand\W|\W\&\W)/
        #intersections.  print as is
        address.gsub!(/(\Wand\W|\W\&\W)/, " and ")
        arr = ["", address, "", ""]
      else
        regex[:address] = Regexp.new('^\W*(' + regex[:number].source + '\\W)?\W*(?:' + regex[:fraction].source + '\W*)?' + regex[:street].source, Regexp::IGNORECASE)
        arr = regex[:address].match(address).to_a
      end

      number = arr[1].strip if arr[1]
      if arr[2] && (!arr[4] || arr[4].empty?)
        street = arr[2].strip.downcase
      else
        dir = Directional[arr[2].strip.downcase] || arr[2].strip.downcase if arr[2]
        dir.gsub!(/\W/, "") if dir
      end
      street = arr[4].strip.downcase if arr[4] && !street

      self.new(
        {
          :number => number,
          :direction => dir ? dir.upcase : nil,
          :street => titlize(street),
          :type => titlize(type),
          :city => titlize(city),
          :state => state.upcase,
          :zipcode => zipcode
        }
      )
    end
  end
end
