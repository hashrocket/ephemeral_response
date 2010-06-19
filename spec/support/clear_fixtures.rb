module ClearFixtures
  module_function
  def clear_fixtures
    FileUtils.rm_rf EphemeralResponse::Configuration.fixture_directory
    EphemeralResponse::Fixture.clear
  end
end
