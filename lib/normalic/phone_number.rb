module Normalic
  # only handles U.S. phone numbers
  class PhoneNumber
    attr_accessor :npa, :nxx, :slid

    def initialize(fields={})
      @npa = fields[:npa]
      @nxx = fields[:nxx]
      @slid = fields[:slid]
    end

    def self.parse(raw)
      digs = raw.to_s.gsub(/[^\d]/,'')
      while digs != (trim = digs.gsub(/^[01]/,''))
        digs = trim
      end
      if digs.length < 10
        return nil
      end
      self.new(:npa => digs[0,3],
               :nxx => digs[3,3],
               :slid => digs[6,4])
    end

    def to_s
      "#{npa} #{nxx} #{slid}"
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

    def ==(other)
      if self.to_s == other.to_s
        true
      else
        false
      end
    end
  end
end
