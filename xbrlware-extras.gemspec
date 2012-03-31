# -*- encoding: utf-8 -*-
require File.expand_path('../lib/xbrlware-extras/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jim Lindstrom"]
  gem.email         = ["jim.lindstrom@gmail.com"]
  gem.description   = %q{A set of extentions that make it easier to build on top of xbrlware}
  gem.summary       = %q{A set of extentions that make it easier to build on top of xbrlware}
  gem.homepage      = ""

  gem.add_dependency("xbrlware-ruby19", "1.1.2.19")

  gem.add_development_dependency("rspec", "~> 2.0.1")

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "xbrlware-extras"
  gem.require_paths = ["lib"]
  gem.version       = Xbrlware::Extras::VERSION
end
