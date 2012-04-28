require 'spec_helper'

describe CloudSearchRails::Search do

  before(:all) do

    MockClass = Class.new(ActiveRecord::Base) do
      indexed_with_cloud_search do |config|
        config.cloud_search_domain = "mock-class"
      end
    end

  end

  context "#cloud_search" do

    it "should proxy its search request to cloud_search and return
      an Arel-like object" do

      search_request = AWSCloudSearch::SearchRequest.new
      search_request.expects(:q=).with("my query")

      AWSCloudSearch::SearchRequest.stubs(:new => search_request)

      MockClass.cloud_search_connection
        .expects(:search)
        .with(search_request)
        .returns(stub({
          :hits => [
            {"id" => 1},
            {"id" => 2}]
        }))
      proxy = MockClass.cloud_search("my query")
      proxy.proxy_options[:conditions].should eql(
        ["mock_classes.id IN (?)", [1, 2]]
      )

    end

  end
  
end