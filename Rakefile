require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('normalic', '0.1.2') do |p|
  p.description    = "Normalize U.S addresses"
  p.url            = "http://github.com/ericxtang/normalic"
  p.author         = "Eric Tang"
  p.email          = "eric.x.tang@gmail.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.development_dependencies = []
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }

