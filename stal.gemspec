Gem::Specification.new do |s|
  s.name = "stal"
  s.version = "0.2.0"
  s.summary = %{Set algebra solver for Redis}
  s.description = %Q{Stal receives s-expressions and resolves the set operations in Redis}
  s.authors = ["Michel Martens"]
  s.email = ["michel@soveran.com"]
  s.homepage = "https://github.com/soveran/stal"
  s.license = "MIT"

  s.files = `git ls-files`.split("\n")

  s.add_dependency "redic", "~> 1.5"
  s.add_development_dependency "cutest", "~> 0"
end
