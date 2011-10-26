require 'cgi'

module Normalic
  class URI
    attr_accessor :scheme, :user,
                  :subdomain, :domain, :tld,
                  :port, :path, :query_hash, :fragment

    def initialize(fields={})
      @scheme = fields[:scheme]
      @user = fields[:user]
      @subdomain = fields[:subdomain]
      @domain = fields[:domain]
      @tld = fields[:tld]
      @port = fields[:port]
      @path = fields[:path]
      @query_hash = fields[:query_hash]
      @fragment = fields[:fragment]
    end

    def self.parse(raw)
      url = raw.to_s.clone

      # parts before the authority, left-to-right
      scheme = url.cut!(/^\w+:\/\//) and scheme.cut!(/:\/\/$/)
      scheme ||= 'http'

      # parts after the authority, right-to-left
      fragment = url.cut!(/#.*$/) and fragment.cut!(/^#/)
      query = url.cut!(/\?.*$/) and query.cut!(/^\?/)
      query_hash = query ? self.parse_query(query) : nil
      path = self.normalize_path(url.cut!(/\/.*$/))

      # parse the authority
      user = url.cut!(/^.+@/) and user.cut!(/@$/)
      port = url.cut!(/:\d+$/) and port.cut!(/^:/)
      tld = url.cut!(/\.\w+$/) and tld.cut!(/^\./)
      domain = url.cut!(/(\.|\A)\w+$/) and domain.cut!(/^\./)
      subdomain = url.empty? ? 'www' : url

      return nil unless tld && domain

      self.new(:scheme => scheme,
               :user => user,
               :subdomain => subdomain,
               :domain => domain,
               :tld => tld,
               :port => port,
               :path => path,
               :query_hash => query_hash,
               :fragment => fragment)
    end

    def to_s
      scheme_s = scheme ? scheme + '://' : nil
      user_s = user ? user + '@' : nil

      host_s = [subdomain, domain, tld].select do |e|
        e ? true : false
      end.join('.')
      host_s = nil if host_s == ''

      port_s = port ? ':' + port : nil
      path_s = path

      if query_hash
        query_s = '?' + query_hash.to_a.collect do |kv|
          kv[0].to_s + '=' + kv[1].to_s
        end.join('&')
      else
        query_s = nil
      end

      fragment_s = fragment ? '#' + fragment : nil

      [scheme_s, user_s, host_s, port_s,
       path_s, query_s, fragment_s].select do |e|
         e ? true : false
       end.join
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
      self.to_s == other.to_s ? true : false
    end

    def match_essential?(other)
      return false unless tld == other.tld
      return false unless domain == other.domain
      return false unless subdomain == other.subdomain ||
                          (subdomain == 'www' && !other.subdomain) ||
                          (!subdomain && other.subdomain == 'www')
      true
    end

    private

    def self.normalize_path(raw)
      parts = raw.to_s.split('/')
      clean_parts = parts.inject([]) do |cpts, pt|
        if pt.empty? || pt == '.'
          cpts
        elsif pt == '..'
          cpts[0..-2]
        else
          cpts + [pt]
        end
      end
      '/' + clean_parts.join('/')
    end

    def self.parse_query(raw)
      url = raw.to_s.clone
      url.cut!(/^\?/)
      kvs = url.split('&')

      query_hash = {}
      kvs.each do |kv|
        k, v = kv.split('=')
        query_hash[k] = CGI.unescape(v || '')
      end
      query_hash
    end
  end
end
