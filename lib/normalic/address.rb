require File.expand_path('../constants', File.dirname(__FILE__))

module Normalic
  # only handles U.S. addresses
  class Address
    UNIT_TYPE_REGEX = /ap(artmen)?t|box|building|bldg|dep(artmen)?t|fl(oor)?|po( box)?|r(oo)?m|s(ui)?te|un(i)?t/
    REGEXES = {:country => /usa|ca/,
               :zipcode => /((\d{5}(-\d{4})?)|([abceghjklmnrstvxy]{1}\d{1}[a-z]{1} ?\d{1}[a-z]{1}\d{1}))/,
               :state => Regexp.new(STATE_CODES.values * '|' + '|' +
                                    STATE_CODES.keys * '|'),
               :city => /\w+(\s\w+)*/,
               :unit => Regexp.new('(#\w+)|' +
                                   '(#?\w+\W+(' + UNIT_TYPE_REGEX.source + '))|' +
                                   '((' + UNIT_TYPE_REGEX.source + ')\W+#?\w+)'),
               :directional => Regexp.new(DIRECTIONAL.keys * '|' + '|' +
                                          DIRECTIONAL.values * '|'),
               :type => Regexp.new(STREET_TYPES_LIST * '|'),
               :number => /\d+/,
               :street => /\w+(\s\w+)*/,
               :intersection => /(.+)\W+(and|&)\W+(.+)/}

    attr_accessor :number, :direction, :street, :type, :unit, :city, :state, :zipcode, :intersection

    def initialize(fields={})
      @number = fields[:number]
      @direction = fields[:direction]
      @street = fields[:street]
      @type = fields[:type]
      @unit = fields[:unit]
      @city = fields[:city]
      @state = fields[:state]
      @zipcode = fields[:zipcode]
      @intersection = fields[:intersection] || false
    end

    def self.parse(raw)
      clean = clean(raw)
      tokens = tokenize(clean)
      normd = normalize(tokens)

      self.new(normd)
    end

    def self.normalize_fields(fields)
      clean_fields = Hash[*fields.collect do |(k, v)|
        k2 = k.is_a?(Symbol) ? k : clean(k).gsub(/\W+/,'').to_sym
        [k2, clean(v)]
      end.flatten(1)]
      if (address = clean_fields.delete(:address) ||
                    clean_fields.delete(:address_line1))
        clean_fields.merge!(Hash[[:type, :street, :direction,
                                  :number, :unit].zip(tokenize_street(address))])
      end
      normd = normalize(clean_fields)

      self.new(normd)
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
      parts = [line1, city, state].select {|e| e ? true : false}
      parts.join(', ') + (zipcode ? ' ' + zipcode : '')
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

    def ==(other)
      self.to_s == other.to_s ? true : false
    end

    def match_essential?(other)
      return false unless zipcode == other.zipcode
      return false unless state == other.state
      return false unless city == other.city
      return false unless street == other.street
      return false unless number == other.number
      return false unless !type || !other.type ||
                          type == other.type
      return false unless !direction || !other.direction ||
                          direction == other.direction
      return false unless !unit || !other.unit ||
                          unit == other.unit
      true
    end

    private

    def self.titlize(str)
      if str
        str.gsub(/\w+/){|w| w.capitalize}
      else
        nil
      end
    end

    def self.clean(raw)
      address = raw.to_s.dup

      address.downcase!
      address.gsub!("\n",', ')
      address.strip!
      address.gsub!(/\s+/,' ')
      address.gsub!('.', '')

      address
    end

    def self.tokenize(address)
      address = address.dup

      address.detoken!(REGEXES[:country])
      zipcode = address.detoken!(REGEXES[:zipcode])

      state = address.detoken!(REGEXES[:state])

      if zipcode && ZIP_CITY_MAP[zipcode] &&
         (zipcity = ZIP_CITY_MAP[zipcode][:city])
        city = address.detoken!(Regexp.new(zipcity))
      end
      unless city
        city = address.cut!(Regexp.new('\W*,\W+(' + REGEXES[:city].source +
                                       ')\W*$'))
        city = city.cut!(REGEXES[:city]) if city
      end

      if m = address.match(REGEXES[:intersection])
        intersection = true
        t1, s1, d1 = tokenize_street(m[1], false)
        t2, s2, d2 = tokenize_street(m[3], false)
        type = [t1, t2]
        street = [s1, s2]
        direction = [d1, d2]
        number = nil
      else
        intersection = false
        type, street, direction, number, unit = tokenize_street(address)
      end

      {:zipcode => zipcode,
       :state => state,
       :city => city,
       :type => type,
       :unit => unit,
       :street => street,
       :direction => direction,
       :number => number,
       :intersection => intersection}
    end

    def self.tokenize_street(address, has_number=true)
      address = address.dup

      number = has_number ? address.detoken_front!(REGEXES[:number]) : nil
      unit = address.detoken!(REGEXES[:unit])
      direction = address.detoken_front!(REGEXES[:directional]) ||
                  address.detoken_rstrip!(REGEXES[:directional])
      type = address.detoken_rstrip!(REGEXES[:type])
      street = address.detoken!(REGEXES[:street])
      if unit && has_number
        return type, street, direction, number, unit
      elsif has_number
        return type, street, direction, number
      else
        return type, street, direction
      end
    end

    def self.normalize(tokens)
      tokens = tokens.clone

      tokens[:zipcode] = normalize_zipcode(tokens[:zipcode])
      tokens[:state] = normalize_state(tokens[:state], tokens[:zipcode])
      tokens[:city] = normalize_city(tokens[:city], tokens[:zipcode])

      if tokens[:intersection]
        tokens[:type].collect! {|t| normalize_type(t)}
        tokens[:street].collect! {|s| normalize_street(s)}
        tokens[:direction].collect! {|d| normalize_direction(d)}
      else
        tokens[:type] = normalize_type(tokens[:type])
        tokens[:street] = normalize_street(tokens[:street])
        tokens[:direction] = normalize_direction(tokens[:direction])
        tokens[:unit] = normalize_unit(tokens[:unit])
      end

      tokens
    end

    def self.normalize_zipcode(zipcode)
      return nil unless zipcode
      if (6..7).include? zipcode.length
        "#{zipcode[0..2]} #{zipcode[-3..-1]}".upcase
      else
        zipcode[0, 5]
      end
    end

    def self.normalize_state(state, zipcode=nil)
      if zipcode && ZIP_CITY_MAP[zipcode]
        state = ZIP_CITY_MAP[zipcode][:state]
        state.upcase
      elsif state
        state = STATE_CODES[state] || state
        state.upcase
      else
        nil
      end
    end

    def self.normalize_city(city, zipcode=nil)
      city = ZIP_CITY_MAP[zipcode][:city] if zipcode && ZIP_CITY_MAP[zipcode]
      city ? titlize(city) : nil
    end

    def self.normalize_type(type)
      if type
        type = STREET_TYPES[type] || type
        titlize(type) + '.'
      else
        nil
      end
    end

    def self.normalize_unit(unit)
      unit ? titlize(unit) : nil
    end

    def self.normalize_street(street)
      street ? titlize(street) : nil
    end

    def self.normalize_direction(direction)
      if direction
        direction = DIRECTIONAL[direction] || direction
        direction.upcase
      else
        nil
      end
    end
  end
end
