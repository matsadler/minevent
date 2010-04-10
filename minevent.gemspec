Gem::Specification.new do |s|
  s.name = "minevent"
  s.version = "0.0.1"
  s.summary = "A pure Ruby evented IO library"
  s.description = "Minevent is a very small evented IO library for Ruby, written in Ruby."
  s.files = Dir["lib/**/*.rb"]
  s.require_path = "lib"
  s.has_rdoc = true
  s.extra_rdoc_files = ["readme.rdoc"]
  s.rdoc_options << "--main" << "readme.rdoc"
  s.author = "Matthew Sadler"
  s.email = "mat@sourcetagsandcodes.com"
  s.homepage = "http://github.com/matsadler/minevent"
  s.add_dependency("events", [">= 0.9.0"])
end