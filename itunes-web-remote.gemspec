require 'rubygems'
require 'rake'

SPEC = Gem::Specification.new do |s|
    s.name = "itunes-web-remote"
    s.version = "0.1.1"
    s.summary = "Minimal ITunes Web Remote Controll."
    s.authors = ["Standa Opichal", "Ole Friis Østergaard"]
    s.email = "opichals@gmail.com"
#s.homepage = "http://code.google.com/p/..."
#s.rubyforge_project = '...'
    s.platform = Gem::Platform::RUBY

    s.files = FileList['lib/**/*.rb', 'bin/*']
    s.require_path = "lib"
#s.test_file = "test/kind_dom_test.rb"

    s.has_rdoc = true
    s.extra_rdoc_files = ["README"]

    s.add_dependency("rb-appscript")
    s.add_dependency("sinatra")
end
