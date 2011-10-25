# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{normalic}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Eric Tang}]
  s.date = %q{2011-10-25}
  s.description = %q{Normalize U.S addresses}
  s.email = %q{eric.x.tang@gmail.com}
  s.extra_rdoc_files = [%q{README.rdoc}, %q{lib/constants.rb}, %q{lib/normalic.rb}, %q{lib/normalic/address.rb}, %q{lib/normalic/phone_number.rb}, %q{lib/normalic/uri.rb}]
  s.files = [%q{Manifest}, %q{README.rdoc}, %q{Rakefile}, %q{lib/constants.rb}, %q{lib/normalic.rb}, %q{lib/normalic/address.rb}, %q{lib/normalic/phone_number.rb}, %q{lib/normalic/uri.rb}, %q{spec/normalic_spec.rb}, %q{normalic.gemspec}]
  s.homepage = %q{http://github.com/ericxtang/normalic}
  s.rdoc_options = [%q{--line-numbers}, %q{--inline-source}, %q{--title}, %q{Normalic}, %q{--main}, %q{README.rdoc}]
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{normalic}
  s.rubygems_version = %q{1.8.5}
  s.summary = %q{Normalize U.S addresses}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
