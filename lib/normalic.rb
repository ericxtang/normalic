require 'rubygems'
require 'ruby-debug'

require 'constants'

module Normalic
  # only handles U.S. phone numbers
  class PhoneNumber
    attr_accessor :npa, :nxx, :slid, :ext

    def initialize(fields={})
      @npa = fields[:npa]
      @nxx = fields[:nxx]
      @slid = fields[:slid]
      @ext = fields[:ext]
    end

    def self.parse(raw)
      digs = raw.to_s.gsub(/[^\d]/,'')
      while digs != (trim = digs.gsub(/^[01]/,''))
        digs = trim
      end
      if digs.length < 10
        raise(ParseError, 'Invalid phone number: less than 10 digits')
      end
      self.new(:npa => digs[0,3],
               :nxx => digs[3,3],
               :slid => digs[6,4],
               :ext => digs.length > 10 ? digs[10..-1] : nil)
    end

    def to_s
      "#{npa} #{nxx} #{slid}" + (ext ? " #{ext}" : '')
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
  end

  # only handles U.S. addresses
  class Address
    UNIT_TYPE_REGEX = /ap(artmen)?t|box|building|bldg|dep(artmen)?t|fl(oor)?|po( box)?|r(oo)?m|s(ui)?te|un(i)?t/
    REGEXES = {:country => /usa/,
               :zipcode => /\d{5}(-\d{4})?/,
               :state => Regexp.new(StateCodes.values * '|' + '|' +
                                    StateCodes.keys * '|'),
               :city => /\w+(\s\w+)*/,
               :unit => Regexp.new('(#?\w+\W+(' + UNIT_TYPE_REGEX.source + '))|' +
                                   '((' + UNIT_TYPE_REGEX.source + ')\W+#?\w+)'),
               :directional => Regexp.new(Directional.keys * '|' + '|' +
                                          Directional.values * '|'),
               :type => Regexp.new(StreetTypesList * '|'),
               :number => /\d+/,
               :street => /\w+(\s\w+)*/,
               :intersection => /(.+)\W+(and|&)\W+(.+)/}

    attr_accessor :number, :direction, :street, :type, :city, :state, :zipcode, :intersection

    def initialize(fields={})
      @number = fields[:number]
      @direction = fields[:direction]
      @street = fields[:street]
      @type = fields[:type]
      @city = fields[:city]
      @state = fields[:state]
      @zipcode = fields[:zipcode]
      @intersection = fields[:intersection] || false
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
      parts = [line1, city, state, zipcode].select {|e| e ? true : false}
      parts.join(', ')
    end

    def line1
      if intersection
        parts1 = [direction[0], street[0], type[0]].select {|e| e ? true : false}
        parts2 = [direction[0], street[0], type[0]].select {|e| e ? true : false}
        parts1.join(' ') + " and " + parts2.join(' ')
      else
        parts = [number, direction, street, type].select {|e| e ? true : false}
        parts.join(' ')
      end
    end

    def self.parse(address)
      address = self.clean(address)
      tokens = self.tokenize(address)
      normd = self.normalize(tokens)

      self.new(normd)
    end

    private

    def self.titlize(str)
      if str
        str.gsub(/\w+/){|w| w.capitalize}
      else
        nil
      end
    end

    def self.clean(address)
      address = address.clone

      address.downcase!
      address.gsub!("\n",', ')
      address.strip!
      address.gsub!(/\s+/,' ')
      address.gsub!('.', '')

      address
    end

    def self.tokenize(address)
      address = address.clone

      address.detoken!(REGEXES[:country])
      zipcode = address.detoken!(REGEXES[:zipcode])
      state = address.detoken!(REGEXES[:state])

      if zipcode && (zipcity = ZipCityMap[zipcode])
        city = address.detoken!(Regexp.new(zipcity))
      end
      unless city
        city = address.cut!(Regexp.new('\W*,\W+(' + REGEXES[:city].source +
                                       ')\W*$'), 1)
        city = city.cut!(REGEXES[:city]) if city
      end

      address.detoken_rstrip!(REGEXES[:unit])

      if m = address.match(REGEXES[:intersection])
        intersection = true
        t1, s1, d1 = self.tokenize_street(m[1], false)
        t2, s2, d2 = self.tokenize_street(m[3], false)
        type = [t1, t2]
        street = [s1, s2]
        direction = [d1, d2]
        number = nil
      else
        intersection = false
        type, street, direction, number = self.tokenize_street(address)
      end

      {:zipcode => zipcode,
       :state => state,
       :city => city,
       :type => type,
       :street => street,
       :direction => direction,
       :number => number,
       :intersection => intersection}
    end

    def self.tokenize_street(address, has_number=true)
      address = address.clone

      number = has_number ? address.detoken_front!(REGEXES[:number]) : nil
      direction = address.detoken_front!(REGEXES[:directional]) ||
                  address.detoken_rstrip!(REGEXES[:directional])
      type = address.detoken_rstrip!(REGEXES[:type])
      street = address.detoken!(REGEXES[:street])
      if has_number
        return type, street, direction, number
      else
        return type, street, direction
      end
    end

    def self.normalize(tokens)
      tokens = tokens.clone

      tokens[:zipcode] = self.normalize_zipcode(tokens[:zipcode])
      tokens[:state] = self.normalize_state(tokens[:state])
      tokens[:city] = self.normalize_city(tokens[:city], tokens[:zipcode])

      if tokens[:intersection]
        tokens[:type].collect! {|t| self.normalize_type(t)}
        tokens[:street].collect! {|s| self.normalize_street(s)}
        tokens[:direction].collect! {|d| self.normalize_direction(d)}
      else
        tokens[:type] = self.normalize_type(tokens[:type])
        tokens[:street] = self.normalize_street(tokens[:street])
        tokens[:direction] = self.normalize_direction(tokens[:direction])
      end

      tokens
    end

    def self.normalize_zipcode(zipcode)
      zipcode ? zipcode[0,5] : nil
    end

    def self.normalize_state(state)
      if state
        state = StateCodes[state] || state
        state.upcase
      else
        nil
      end
    end

    def self.normalize_city(city, zipcode=nil)
      city = ZipCityMap[zipcode] if zipcode && ZipCityMap[zipcode]
      city ? self.titlize(city) : nil
    end

    def self.normalize_type(type)
      if type
        type = StreetTypes[type] || type
        self.titlize(type) + '.'
      else
        nil
      end
    end

    def self.normalize_street(street)
      street ? self.titlize(street) : nil
    end

    def self.normalize_direction(direction)
      if direction
        direction = Directional[direction] || direction
        direction.upcase
      else
        nil
      end
    end

#    #Iteratively take chunks off of the string.
#    def self.parse(address)
#      address.strip!
#      regex = {
#        :unit => /(((\#?\w*)?\W*(su?i?te|p\W*[om]\W*b(?:ox)?|dept|department|ro*m|floor|fl|apt|apartment|unit|box))$)|(\W((su?i?te|p\W*[om]\W*b(?:ox)?|dept|department|ro*m|floor|fl|apt|apartment|unit|box)\W*(\#?\w*)?)\W{0,3}$)/i,
#        :direct => Regexp.new(Directional.keys * '|' + '|' + Directional.values * '\.?|',Regexp::IGNORECASE),
#        :type => Regexp.new('(' + StreetTypes_list * '|' + ')\\W*?$',Regexp::IGNORECASE),
#        :number => /\d+-?\d*/,
#        :fraction => /\d+\/\d+/,
#        :country => /\W+USA$/,
#        :zipcode => /\W+(\d{5}|\d{5}-\d{4})$/,
#        :state => Regexp.new('\W+(' + StateCodes.values * '|' + '|' + StateCodes.keys * '|' + ')$',Regexp::IGNORECASE),
#      }
#      regex[:street] = Regexp.new('((' + regex[:direct].source + ')\\W)?\\W*(.*)\\W*(' + regex[:type].source + ')?', Regexp::IGNORECASE)
#
#      #get rid of USA at the end
#      country_code = address[regex[:country]]
#      address.gsub!(regex[:country], "")
#
#      zipcode = address[regex[:zipcode]]
#      address.gsub!(regex[:zipcode], "")
#      zipcode.gsub!(/\W/, "") if zipcode
#
#      state = address[regex[:state]]
#      address.gsub!(regex[:state], "")
#      state.gsub!(/(^\W*|\W*$)/, "").downcase! if state
#      state = StateCodes[state] || state
#
#      if ZipCityMap[zipcode]
#        regex[:city] = Regexp.new("\\W+" + ZipCityMap[zipcode] + "$", Regexp::IGNORECASE)
#        regex[:city] = /,.*$/ if !address[regex[:city]]
#        city = ZipCityMap[zipcode]
#      else
#        regex[:city] = /,.*$/
#        city = address[regex[:city]] 
#        city.gsub!(/(^\W*|\W*$)/, "").downcase! if city
#      end
#
#      address.gsub!(regex[:city], "")
#      address.gsub!(regex[:unit], "")
#      address.gsub!(Regexp.new('\W(' + regex[:direct].source + ')\\W{0,3}$', Regexp::IGNORECASE), "")
#
#      type = address[regex[:type]]
#      address.gsub!(regex[:type], "")
#      type.gsub!(/(^\W*|\W*$)/, "").downcase! if type
#      type = StreetTypes[type] || type if type
#
#      # arr: [ , , , ]
#      if address =~ /(\Wand\W|\W\&\W)/
#        #intersections.  print as is
#        address.gsub!(/(\Wand\W|\W\&\W)/, " and ")
#        arr = ["", address, "", ""]
#      else
#        regex[:address] = Regexp.new('^\W*(' + regex[:number].source + '\\W)?\W*(?:' + regex[:fraction].source + '\W*)?' + regex[:street].source, Regexp::IGNORECASE)
#        arr = regex[:address].match(address).to_a
#      end
#
#      number = arr[1].strip if arr[1]
#      if arr[2] && (!arr[4] || arr[4].empty?)
#        street = arr[2].strip.downcase
#      else
#        dir = Directional[arr[2].strip.downcase] || arr[2].strip.downcase if arr[2]
#        dir.gsub!(/\W/, "") if dir
#      end
#      street = arr[4].strip.downcase if arr[4] && !street
#
#      self.new(
#        {
#          :number => number,
#          :direction => dir ? dir.upcase : nil,
#          :street => titlize(street),
#          :type => titlize(type),
#          :city => titlize(city),
#          :state => state ? state.upcase : nil,
#          :zipcode => zipcode
#        }
#      )
#    end
  end

  class ParseError < StandardError; end

  private

  String.class_eval do
    def detoken!(regex)
      regex_p = Regexp.new('(\W+|\A)(' + regex.source + ')$', regex.options)
      oldself = self.clone
      self.cut!(regex_p) ? oldself.match(regex_p)[2] : nil
    end

    def detoken_rstrip!(regex)
      regex_p = Regexp.new('.*((\W|\A)(' + regex.source + ')\W.*)', regex.options)
      oldself = self.clone
      self.cut!(regex_p, 1) ? oldself.match(regex_p)[3] : nil
    end

    def detoken_front!(regex)
      regex_p = Regexp.new('^(' + regex.source + ')(\W+|\Z)', regex.options)
      oldself = self.clone
      self.cut!(regex_p) ? oldself.match(regex_p)[1] : nil
    end

#    def splitr(regex, match_index=0)
#      if match = self.match(regex)
#        i1, i2 = match.offset(match_index)
#        j1, j2 = match.offset(0)
#        return self[0...j1], self[i1...i2], self[j2...self.length]
#      else
#        self, nil, nil
#      end
#    end

    def cut!(regex, match_index=0)
      if match = self.match(regex)
        i1, i2 = match.offset(match_index)
        self[i1...i2] = ''
        match[match_index]
      else
        nil
      end
    end
  end
end
