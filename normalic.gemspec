# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "normalic"
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Eric Tang"]
  s.date = "2011-11-01"
  s.description = "Normalize U.S addresses"
  s.email = "eric.x.tang@gmail.com"
  s.extra_rdoc_files = ["README.rdoc", "lib/constants.rb", "lib/normalic.rb", "lib/normalic/address.rb", "lib/normalic/phone_number.rb", "lib/normalic/uri.rb"]
  s.files = ["Manifest", "README.rdoc", "Rakefile", "lib/constants.rb", "lib/normalic.rb", "lib/normalic/address.rb", "lib/normalic/phone_number.rb", "lib/normalic/uri.rb", "spec/normalic_spec.rb", "normalic.gemspec"]
  s.homepage = "http://github.com/ericxtang/normalic"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Normalic", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "normalic"
  s.rubygems_version = "1.8.10"
  s.summary = "Normalize U.S addresses"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
