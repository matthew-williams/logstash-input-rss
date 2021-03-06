# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/rss"
require 'ostruct'

describe LogStash::Inputs::Rss do
  describe "stopping" do
    let(:config) { {"url" => "localhost", "interval" => 10} }
    before do
      allow(Faraday).to receive(:get)
      allow(subject).to receive(:handle_response)
    end
    it_behaves_like "an interruptible input plugin"
  end

  shared_examples "fetching data" do |type|
    let(:config) do
      {
        "url" => "http://www.example.com/foo.rss",
        "interval" => 10
      }
    end

    let(:sample) do
      body = File.read(File.join(fixtures_source, "sample-feed.xml"))
      OpenStruct.new(:body => body)
    end

    before(:each) do
      allow(Faraday).to receive(:get).with(config["url"]).and_return(sample)
    end

    context "when the feed is valid" do
      let(:data) do
        plugin = described_class.new(config)
        plugin_input(plugin) do |queue|
          sleep 0.1 while queue.empty?
          events = []
          queue.size.times { |i| events << queue.pop }
          events
        end
      end

      it "fetchs all items" do
        expect(data.count).to be > 0
      end
    end

    context "when the feed is invalid" do

      let(:sample) do
        body = File.read(File.join(fixtures_source, "invalid-feed.xml"))
        OpenStruct.new(:body => body)
      end

      let(:plugin) { described_class.new(config) }

      it "fetchs no items and causes no errors" do
        events = []
        expect {
          plugin_input(plugin) do |queue|
            sleep 1
            events = []
            queue.size.times { |i| events << queue.pop }
            events
          end
        }.not_to raise_error
        expect(events.count).to be == 0
      end
    end

    context "when the feed is valid, but has zero items" do

      let(:sample) do
        body = File.read(File.join(fixtures_source, "zero-items-feed.xml"))
        OpenStruct.new(:body => body)
      end

      let(:plugin) { described_class.new(config) }

      it "fetchs no items and causes no errors" do
        events = []
        expect {
          plugin_input(plugin) do |queue|
            sleep 1
            events = []
            queue.size.times { |i| events << queue.pop }
            events
          end
        }.not_to raise_error
        expect(events.count).to be == 0
      end
    end

  end

  describe "rss feed" do
    let(:fixtures_source) { File.join(File.dirname(__FILE__), "..", "fixtures", "rss")  }
    it_behaves_like "fetching data"
  end

  describe "atom feed" do
    let(:fixtures_source) { File.join(File.dirname(__FILE__), "..", "fixtures", "atom")  }
    it_behaves_like "fetching data"
  end

end
