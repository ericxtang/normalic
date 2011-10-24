require File.expand_path('./normalic/uri', File.dirname(__FILE__))
require File.expand_path('./normalic/phone_number', File.dirname(__FILE__))
require File.expand_path('./normalic/address', File.dirname(__FILE__))

module Normalic
  private

  String.class_eval do
    def detoken!(regex)
      regex_p = Regexp.new('(\W+|\A)(' + regex.source + ')$', regex.options)
      oldself = self.clone
      self.cut!(regex_p) ? oldself.match(regex_p)[2] : nil
    end

    def detoken_rstrip!(regex)
      regex_p = Regexp.new('.*((\W|\A)(' + regex.source + ')(\W.*|\Z))', regex.options)
      oldself = self.clone
      self.cut!(regex_p, 1) ? oldself.match(regex_p)[3] : nil
    end

    def detoken_front!(regex)
      regex_p = Regexp.new('^(' + regex.source + ')(\W+|\Z)', regex.options)
      oldself = self.clone
      self.cut!(regex_p) ? oldself.match(regex_p)[1] : nil
    end

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
