require 'net/http'
require 'fileutils'
require 'time'
require 'delegate'
require 'digest/sha1'
require 'psych'
require 'yaml'
require 'ephemeral_response/configuration'
require 'ephemeral_response/request'
require 'ephemeral_response/fixture'
require 'ephemeral_response/null_output'

module EphemeralResponse
  VERSION = "0.4.0".freeze

  Error = Class.new(StandardError)

  def self.activate
    deactivate
    load 'ephemeral_response/net_http.rb'
    Fixture.load_all
  end

  def self.configure
    yield Configuration if block_given?
    Configuration
  end

  def self.fixture_set
    Configuration.fixture_set
  end

  def self.fixture_set=(name)
    Configuration.fixture_set = name
    Fixture.load_all
  end

  def self.deactivate
    Net::HTTP.class_eval do
      remove_method(:generate_uri) if method_defined?(:generate_uri)
      remove_method(:uri) if method_defined?(:uri)
      alias_method(:connect, :connect_without_ephemeral_response) if private_method_defined?(:connect_without_ephemeral_response)
      alias_method(:request, :request_without_ephemeral_response) if method_defined?(:request_without_ephemeral_response)
    end
    Net::HTTPResponse.class_eval do
      alias_method(:procdest, :procdest_without_ephemeral_response) if private_method_defined?(:procdest_without_ephemeral_response)
      alias_method(:read_body, :read_body_without_ephemeral_response) if method_defined?(:read_body_without_ephemeral_response)
    end
  end

  def self.fixtures
    Fixture.fixtures
  end

  # FIXME: Don't deactivate and reactivate, instead set a flag which ignores
  # fixtures entirely.
  def self.live
    deactivate
    yield
    activate
  end
end
