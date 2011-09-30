Gem::Specification.new do |s|
  s.name = %q{ephemeral_response}
  s.version = "0.4.0"
  s.platform = Gem::Platform::RUBY
  s.required_rubygems_version = ">= 1.3.6"
  s.authors = ["Sandro Turriate", "Les Hill"]
  s.date = Time.now.strftime('%F')
  s.email = %q{sandro.turriate@gmail.com}
  s.files = [
    ".document",
    ".gitignore",
    ".rvmrc",
    "Gemfile",
    "History.markdown",
    "MIT_LICENSE",
    "README.markdown",
    "Rakefile",
    "VERSION",
    "ephemeral_response.gemspec",
    "examples/custom_cache_key.rb",
    "examples/open_uri_compatibility.rb",
    "examples/simple_benchmark.rb",
    "examples/white_list.rb",
    "lib/ephemeral_response.rb",
    "lib/ephemeral_response/configuration.rb",
    "lib/ephemeral_response/fixture.rb",
    "lib/ephemeral_response/net_http.rb",
    "lib/ephemeral_response/null_output.rb",
    "lib/ephemeral_response/request.rb",
    "spec/ephemeral_response/configuration_spec.rb",
    "spec/ephemeral_response/fixture_spec.rb",
    "spec/ephemeral_response/net_http_spec.rb",
    "spec/ephemeral_response_spec.rb",
    "spec/integration/custom_identifier_spec.rb",
    "spec/integration/normal_flow_spec.rb",
    "spec/integration/read_body_compatibility_spec.rb",
    "spec/integration/sets_spec.rb",
    "spec/integration/unique_fixtures_spec.rb",
    "spec/integration/white_list_spec.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb",
    "spec/support/clear_fixtures.rb",
    "spec/support/fakefs_ext.rb",
    "spec/support/rack_reflector.rb",
    "spec/support/time.rb"
  ]
  s.homepage = %q{http://github.com/sandro/ephemeral_response}
  s.rdoc_options = [%q{--charset=UTF-8}]
  s.require_paths = [%q{lib}]
  s.description = %q{Save HTTP responses to give your tests a hint of reality. Responses are saved into your fixtures directory and are used for subsequent web requests until they expire.}
  s.summary = %q{Save HTTP responses to give your tests a hint of reality.}
  s.test_files = Dir["{spec}/**/*.rb", "{examples}/**/*.rb"]
  s.extra_rdoc_files = [%q{README.markdown}]
end

