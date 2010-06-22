require 'spec_helper'

describe EphemeralResponse::Fixture do
  include FakeFS::SpecHelpers

  let(:fixture_directory) { File.expand_path EphemeralResponse::Configuration.fixture_directory }
  let(:request) { Net::HTTP::Get.new '/' }
  let(:uri) { URI.parse("http://example.com/") }
  let(:fixture) { EphemeralResponse::Fixture.new(uri, request) { |f| f.response = "hello world"} }

  describe ".load_all" do
    it "returns the empty fixtures hash when the fixture directory doesn't exist" do
      EphemeralResponse::Fixture.should_not_receive :load_fixture
      EphemeralResponse::Fixture.load_all.should == {}
    end

    it "clears old fixtures" do
      EphemeralResponse::Fixture.should_receive(:clear)
      EphemeralResponse::Fixture.load_all
    end

    context "fixture files exist" do
      before do
        FileUtils.mkdir_p fixture_directory
        Dir.chdir(fixture_directory) do
          FileUtils.touch %w(1.yml 2.yml)
        end
      end

      it "calls #load_fixture for each fixture file" do
        EphemeralResponse::Fixture.should_receive(:load_fixture).with("#{fixture_directory}/1.yml")
        EphemeralResponse::Fixture.should_receive(:load_fixture).with("#{fixture_directory}/2.yml")
        EphemeralResponse::Fixture.load_all
      end
    end
  end

  describe ".load_fixture" do
    it "loads the yamlized fixture into the fixtures hash" do
      fixture.save
      EphemeralResponse::Fixture.load_fixture(fixture.path)
      EphemeralResponse::Fixture.fixtures.should have_key(fixture.identifier)
    end
  end

  describe ".register" do
    context "fixture expired" do
      before do
        fixture.instance_variable_set(:@created_at, Time.new - (EphemeralResponse::Configuration.expiration * 2))
        fixture.register
      end

      it "removes the fixture file" do
        File.exists?(fixture.path).should be_false
      end

      it "does not add the fixture to the fixtures hash" do
        EphemeralResponse::Fixture.fixtures.should_not have_key(fixture.identifier)
      end
    end

    context "fixture not expired" do
      before do
        fixture.register
      end

      it "adds the the fixture to the fixtures hash" do
        EphemeralResponse::Fixture.fixtures[fixture.identifier].should == fixture
      end
    end
  end

  describe ".find" do
    context "when fixture registered" do
      it "returns the fixture" do
        fixture.register
        EphemeralResponse::Fixture.find(uri, request).should == fixture
      end
    end

    context "when fixture not registered" do
      it "returns nil" do
        EphemeralResponse::Fixture.find(uri, request).should be_nil
      end
    end
  end

  describe ".find_or_initialize" do
    context "when the fixture is registered" do
      it "returns the registered fixture" do
        fixture.register
        EphemeralResponse::Fixture.find_or_initialize(uri, request).should == fixture
      end
    end

    context "when the fixture doesn't exist" do
      it "processes the block" do
        EphemeralResponse::Fixture.find_or_initialize(uri, request) do |fixture|
          fixture.response = "bah"
        end.response.should == "bah"
      end

      it "returns the new fixture" do
        fixture = EphemeralResponse::Fixture.find_or_initialize(uri, request)
        EphemeralResponse::Fixture.fixtures[fixture.identifier].should be_nil
      end
    end
  end

  describe ".respond_to" do
    context "host included in white list" do
      before do
        EphemeralResponse::Configuration.white_list = uri.host
      end

      it "returns flow back to net/http" do
        2.times do
          EphemeralResponse::Fixture.respond_to(fixture.uri, request) {}
          EphemeralResponse::Fixture.fixtures[fixture.identifier].should be_nil
        end
      end

      context "uri not normalized" do
        let(:uri) { URI.parse("HtTP://ExaMplE.Com/") }
        let(:fixture) { EphemeralResponse::Fixture.new(uri, request) }

        before do
          EphemeralResponse::Configuration.white_list = "example.com"
        end

        it "returns flow to net/http when host is not normalized" do
          EphemeralResponse::Fixture.respond_to(uri, request) {}
          EphemeralResponse::Fixture.fixtures[fixture.identifier].should be_nil
        end
      end

    end

    context "fixture loaded" do
      it "returns the fixture response" do
        fixture.register
        response = EphemeralResponse::Fixture.respond_to(fixture.uri, request)
        response.should == "hello world"
      end
    end

    context "fixture not loaded" do
      it "sets the response to the block" do
        EphemeralResponse::Fixture.respond_to(fixture.uri, request) do
          "new response"
        end
        EphemeralResponse::Fixture.fixtures[fixture.identifier].response.should == "new response"
      end

      it "saves the fixture" do
        EphemeralResponse::Fixture.respond_to(fixture.uri, request) do
          "new response"
        end
        File.exists?(fixture.path).should be_true
      end
    end
  end

  describe "#initialize" do
    let(:uri) { URI.parse("HtTP://ExaMplE.Com/") }
    subject { EphemeralResponse::Fixture }

    it "normalizes the given uri" do
      fixture = subject.new(uri, request)
      fixture.uri.should == uri.normalize
    end

    it "duplicates the request" do
      fixture = subject.new(uri, request)
      request['something'] = "anything"
      fixture.request['something'].should be_nil
      request['something'].should == "anything"
    end

    it "sets created_at to the current time" do
      Time.travel "2010-01-15 10:11:12" do
        fixture = subject.new(uri, request)
        fixture.created_at.should == Time.parse("2010-01-15 10:11:12")
      end
    end

    it "yields itself" do
      fixture = subject.new(uri, request) do |f|
        f.response = "yielded self"
      end
      fixture.response.should == "yielded self"
    end
  end

  describe "#identifier" do
    let(:request) { Net::HTTP::Get.new '/?foo=bar' }
    let(:uri) { URI.parse "http://example.com/" }
    subject { EphemeralResponse::Fixture.new uri, request }

    it "hashes the uri_identifier with request_identifier" do
      Digest::SHA1.should_receive(:hexdigest).with("#{subject.uri_identifier}#{subject.request_identifier}")
      subject.identifier
    end
  end

  describe "#uri_identifier" do

    it "returns an array containing the host when there is no query string" do
      request = Net::HTTP::Get.new '/'
      host = URI.parse("http://example.com/")
      fixture = EphemeralResponse::Fixture.new(host, request)
      fixture.uri_identifier.should == "http://example.com/"
    end

    it "does not incorrectly hash different hosts which sort identically" do
      request = Net::HTTP::Get.new '/?foo=bar'
      host1 = URI.parse("http://a.com/?f=b")
      host2 = URI.parse("http://f.com/?b=a")
      fixture1 = EphemeralResponse::Fixture.new(host1, request)
      fixture2 = EphemeralResponse::Fixture.new(host2, request)
      fixture1.uri_identifier.should_not == fixture2.uri_identifier
    end

    it "sorts the query strings" do
      uri1 = URI.parse("http://example.com/?foo=bar&baz=qux&f")
      uri2 = URI.parse("http://example.com/?baz=qux&foo=bar&f")
      request1 = Net::HTTP::Get.new uri1.request_uri
      request2 = Net::HTTP::Get.new uri2.request_uri
      fixture1 = EphemeralResponse::Fixture.new(uri1, request1)
      fixture2 = EphemeralResponse::Fixture.new(uri2, request2)
      fixture1.uri_identifier.should == fixture2.uri_identifier
    end

    it "doesn't mix up the query string key pairs" do
      uri1 = URI.parse("http://example.com/?foo=bar&baz=qux")
      uri2 = URI.parse("http://example.com/?bar=foo&qux=baz")
      request1 = Net::HTTP::Get.new uri1.request_uri
      request2 = Net::HTTP::Get.new uri2.request_uri
      fixture1 = EphemeralResponse::Fixture.new(uri1, request1)
      fixture2 = EphemeralResponse::Fixture.new(uri2, request2)
      fixture1.uri_identifier.should_not == fixture2.uri_identifier
    end
  end

  describe "#register" do
    context "uri not white listed" do
      it "saves the fixture" do
        fixture.register
        File.exists?(fixture.path).should be_true
      end

      it "registers the fixture" do
        fixture.register
        EphemeralResponse::Fixture.fixtures.should have_key(fixture.identifier)
      end
    end

    context "uri is white listed" do
      before do
        EphemeralResponse::Configuration.white_list << uri.host
      end

      it "doesn't save the fixture" do
        fixture.register
        File.exists?(fixture.path).should be_false
      end

      it "doesn't register the fixture" do
        fixture.register
        EphemeralResponse::Fixture.fixtures.should_not have_key(fixture.identifier)
      end
    end
  end
end
